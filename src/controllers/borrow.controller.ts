import { Request, Response } from 'express';
import { pool } from '../config/db';

export const issueBook = async (req: Request, res: Response) => {
  const client = await pool.connect();
  try {
    const { borrowerId, isbn, bookTitle } = req.body;

    if (!borrowerId || !isbn) {
      return res.status(400).json({ 
        success: false, 
        message: 'Borrower ID and ISBN are required.' 
      });
    }

    await client.query('BEGIN');

    // 1. RULE: CHECK IF BORROWER ALREADY HAS AN ACTIVE COPY OF THIS EXACT BOOK
    const duplicateCheck = await client.query(
      `SELECT * FROM borrow_records 
       WHERE LOWER(borrower_id) = LOWER($1) 
         AND LOWER(book_isbn) = LOWER($2) 
         AND (status IS NULL OR UPPER(status) NOT IN ('RETURNED', 'RETURN'))
         AND (returned_date IS NULL)`,
      [borrowerId.trim(), isbn.trim()]
    );

    if (duplicateCheck.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        success: false,
        isDuplicate: true,
        message: 'Active copy found! Borrower already holds a copy of this book.',
      });
    }

    // 2. RULE: MAX 3 ACTIVE BOOKS ALLOWED FOR THIS BORROWER ID
    const activeBorrowsCount = await client.query(
      `SELECT COUNT(*) FROM borrow_records 
       WHERE LOWER(borrower_id) = LOWER($1) 
         AND (status IS NULL OR UPPER(status) NOT IN ('RETURNED', 'RETURN'))
         AND (returned_date IS NULL)`,
      [borrowerId.trim()]
    );

    const totalActive = parseInt(activeBorrowsCount.rows[0].count, 10);
    if (totalActive >= 3) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: '🚫 Borrow Limit Reached! A patron can hold a maximum of 3 active books for 6 months.',
      });
    }

    // 3. CHECK STOCK AVAILABILITY
    const bookCheck = await client.query(
      `SELECT * FROM books WHERE LOWER(isbn) = LOWER($1) LIMIT 1`,
      [isbn.trim()]
    );

    if (bookCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Book not found in library stock.',
      });
    }

    const book = bookCheck.rows[0];
    if (book.available_quantity < 1) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Book is currently out of stock.',
      });
    }

    // 4. SET 6-MONTH LOAN PERIOD (180 Days)
    const borrowedDate = new Date();
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 180);

    // 5. INSERT BORROW RECORD
    await client.query(
      `INSERT INTO borrow_records 
        (borrower_id, book_isbn, book_title, borrowed_date, due_date, status) 
       VALUES ($1, $2, $3, $4, $5, 'BORROWED')`,
      [
        borrowerId.trim(),
        isbn.trim(),
        bookTitle || book.title,
        borrowedDate.toISOString(),
        dueDate.toISOString(),
      ]
    );

    // 6. DEDUCT STOCK
    await client.query(
      `UPDATE books 
       SET available_quantity = available_quantity - 1 
       WHERE LOWER(isbn) = LOWER($1)`,
      [isbn.trim()]
    );

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      message: 'Book borrowed successfully for 6 months.',
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    console.error('Error issuing book:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while issuing book.',
    });
  } finally {
    client.release();
  }
};