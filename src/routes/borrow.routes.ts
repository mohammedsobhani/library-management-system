import { Router, Request, Response } from 'express';
import pool from '../config/database'; // Adjust path if your DB config is located elsewhere
// 🛑 THIS IS CORRECT: Importing the default export as 'pool'
import pool from '../config/database';

const router = Router();

// ============================================================================
// 1. REGISTER OR UPDATE BORROWER (Handles Base64 Photo Upload)
// ============================================================================
router.post('/register-borrower', async (req: Request, res: Response): Promise<void> => {
  try {
    const { id, name, role, photoUrl } = req.body;

    if (!id || !name) {
      res.status(400).json({ success: false, message: 'Borrower ID and Name are required.' });
      return;
    }

    const query = `
      INSERT INTO borrowers (id, name, role, photo_url)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (id) 
      DO UPDATE SET 
        name = EXCLUDED.name,
        role = EXCLUDED.role,
        photo_url = COALESCE(EXCLUDED.photo_url, borrowers.photo_url)
      RETURNING *;
    `;

    const result = await pool.query(query, [id, name, role || 'STUDENT', photoUrl || null]);

    res.status(200).json({
      success: true,
      message: 'Borrower registered successfully',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Error in /register-borrower:', error);
    res.status(500).json({
      success: false,
      error: (error as Error).message,
    });
  }
});

// ============================================================================
// 2. FETCH PERSONAL BORROWED BOOKS FOR A PATRON (Student / Teacher / Officer)
// ============================================================================
router.get('/my-books', async (req: Request, res: Response): Promise<void> => {
  try {
    const borrowerId = req.query.borrowerId as string;

    if (!borrowerId) {
      res.status(400).json({
        success: false,
        message: 'Borrower ID or email is required.',
      });
      return;
    }

    const query = `
      SELECT 
        id,
        book_isbn,
        book_title,
        borrowed_date,
        due_date,
        (EXTRACT(DAY FROM (due_date - CURRENT_TIMESTAMP)))::INTEGER AS remaining_days,
        status
      FROM borrow_records
      WHERE borrower_id = $1 AND status = 'BORROWED'
      ORDER BY borrowed_date DESC;
    `;

    const result = await pool.query(query, [borrowerId]);

    res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('Error in /my-books:', error);
    res.status(500).json({
      success: false,
      error: (error as Error).message,
    });
  }
});

// ============================================================================
// 3. ISSUE BOOK (Enforces Max 2 Books Per Month Limit & Updates Stock)
// ============================================================================
router.post('/issue-book', async (req: Request, res: Response): Promise<void> => {
  const client = await pool.connect();

  try {
    const { borrowerId, isbn, bookTitle } = req.body;

    if (!borrowerId || !isbn) {
      res.status(400).json({
        success: false,
        message: 'Borrower ID and ISBN are required.',
      });
      return;
    }

    await client.query('BEGIN');

    // 1. CHECK MONTHLY BORROW LIMIT (Max 2 books per calendar month)
    const monthlyLimitCheck = await client.query(
      `SELECT COUNT(*) AS monthly_count 
       FROM borrow_records 
       WHERE borrower_id = $1 
         AND DATE_TRUNC('month', borrowed_date) = DATE_TRUNC('month', CURRENT_DATE)`,
      [borrowerId]
    );

    const currentMonthBorrows = parseInt(monthlyLimitCheck.rows[0].monthly_count, 10);

    if (currentMonthBorrows >= 2) {
      await client.query('ROLLBACK');
      res.status(400).json({
        success: false,
        message: '🚫 Borrow Limit Reached! A patron can only borrow a maximum of 2 books per month.',
      });
      return;
    }

    // 2. CHECK ACTIVE DUPLICATE BORROW
    const duplicateCheck = await client.query(
      `SELECT id FROM borrow_records 
       WHERE borrower_id = $1 AND book_isbn = $2 AND status = 'BORROWED'`,
      [borrowerId, isbn]
    );

    if (duplicateCheck.rows.length > 0) {
      await client.query('ROLLBACK');
      res.status(409).json({
        success: false,
        isDuplicate: true,
        message: 'Active copy of this book is already issued to this borrower.',
      });
      return;
    }

    // 3. CHECK BOOK STOCK AVAILABILITY
    const stockCheck = await client.query(
      `SELECT available_quantity, title FROM books WHERE isbn = $1 FOR UPDATE`,
      [isbn]
    );

    if (stockCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({
        success: false,
        message: 'Book not found in inventory.',
      });
      return;
    }

    const availableQty = stockCheck.rows[0].available_quantity;
    const resolvedTitle = bookTitle || stockCheck.rows[0].title;

    if (availableQty <= 0) {
      await client.query('ROLLBACK');
      res.status(400).json({
        success: false,
        message: 'Book is currently out of stock.',
      });
      return;
    }

    // 4. DECREMENT AVAILABLE STOCK BY 1
    await client.query(
      `UPDATE books SET available_quantity = available_quantity - 1 WHERE isbn = $1`,
      [isbn]
    );

    // 5. INSERT BORROW RECORD (6 Months / 180 Days Default Due Date)
    const insertQuery = `
      INSERT INTO borrow_records (
        borrower_id, 
        book_isbn, 
        book_title, 
        borrowed_date, 
        due_date, 
        status
      ) VALUES ($1, $2, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '180 days', 'BORROWED')
      RETURNING *;
    `;

    const newRecord = await client.query(insertQuery, [borrowerId, isbn, resolvedTitle]);

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Book issued successfully!',
      data: newRecord.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error in /issue-book:', error);
    res.status(500).json({
      success: false,
      error: (error as Error).message,
    });
  } finally {
    client.release();
  }
});

// ============================================================================
// 4. RETURN BOOK & RESTORE STOCK
// ============================================================================
router.post('/return-book', async (req: Request, res: Response): Promise<void> => {
  const client = await pool.connect();

  try {
    const { isbn } = req.body;

    if (!isbn) {
      res.status(400).json({ success: false, message: 'ISBN is required.' });
      return;
    }

    await client.query('BEGIN');

    // Update record status to RETURNED
    const updateRecord = await client.query(
      `UPDATE borrow_records 
       SET status = 'RETURNED', returned_date = CURRENT_TIMESTAMP 
       WHERE id = (
         SELECT id FROM borrow_records 
         WHERE book_isbn = $1 AND status = 'BORROWED' 
         ORDER BY borrowed_date ASC LIMIT 1
       ) 
       RETURNING *;`,
      [isbn]
    );

    if (updateRecord.rows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({
        success: false,
        message: 'No active borrowed record found for this ISBN.',
      });
      return;
    }

    // Restore stock quantity
    await client.query(
      `UPDATE books SET available_quantity = available_quantity + 1 WHERE isbn = $1`,
      [isbn]
    );

    await client.query('COMMIT');

    res.status(200).json({
      success: true,
      message: 'Book returned successfully, stock restored.',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    res.status(500).json({ success: false, error: (error as Error).message });
  } finally {
    client.release();
  }
});

// ============================================================================
// 5. FETCH ALL BORROW RECORDS (For Admin View)
// ============================================================================
router.get('/borrow-records', async (_req: Request, res: Response): Promise<void> => {
  try {
    const query = `
      SELECT 
        br.*, 
        b.name AS borrower_name, 
        b.role AS borrower_role,
        b.photo_url
      FROM borrow_records br
      LEFT JOIN borrowers b ON br.borrower_id = b.id
      ORDER BY br.borrowed_date DESC;
    `;
    const result = await pool.query(query);
    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: (error as Error).message });
  }
});

export default router;