import { Router, Request, Response } from 'express';
import { pool } from '../config/database';

const router = Router();

/**
 * 1. Search & List Books with Dynamic Stock Quantities
 * Handles partial search queries for titles, authors, or ISBNs.
 */
router.get('/search', async (req: Request, res: Response): Promise<void> => {
  try {
    const q = req.query.q as string;
    let query = `
      SELECT 
        id,
        title,
        isbn,
        author,
        publisher,
        COALESCE(total_quantity, 1) AS total_quantity,
        COALESCE(available_quantity, 1) AS available_quantity
      FROM books
    `;
    const params: any[] = [];

    if (q && q.trim().length > 0) {
      query += ` WHERE LOWER(title) LIKE LOWER($1) OR LOWER(author) LIKE LOWER($1) OR isbn LIKE $1`;
      params.push(`%${q.trim()}%`);
    }

    query += ` ORDER BY created_at DESC`;

    const result = await pool.query(query, params);
    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: (error as Error).message });
  }
});

/**
 * 2. Add or Update Book Stock (Admin Mode / Manual or Barcode Scan)
 * Increments total and available stock if the book already exists.
 */
router.post('/add', async (req: Request, res: Response): Promise<void> => {
  try {
    const { title, isbn, author, publisher, quantity } = req.body;
    const qty = parseInt(quantity, 10) || 1;

    const query = `
      INSERT INTO books (title, isbn, author, publisher, total_quantity, available_quantity)
      VALUES ($1, $2, $3, $4, $5, $5)
      ON CONFLICT (isbn) DO UPDATE 
      SET total_quantity = books.total_quantity + EXCLUDED.total_quantity,
          available_quantity = books.available_quantity + EXCLUDED.available_quantity
      RETURNING *;
    `;

    const result = await pool.query(query, [title, isbn, author, publisher, qty]);
    res.status(201).json({ 
      success: true, 
      message: 'Book stock updated successfully!', 
      data: result.rows[0] 
    });
  } catch (error) {
    res.status(500).json({ success: false, error: (error as Error).message });
  }
});

/**
 * 3. Delete a Book from Library Inventory
 * Removes the book record completely from the database using its UUID.
 */
router.delete('/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const query = `DELETE FROM books WHERE id = $1 RETURNING *;`;
    const result = await pool.query(query, [id]);

    if (result.rowCount === 0) {
      res.status(404).json({ success: false, message: 'Book not found' });
      return;
    }

    res.status(200).json({ 
      success: true, 
      message: 'Book deleted successfully', 
      deletedBook: result.rows[0] 
    });
  } catch (error) {
    res.status(500).json({ success: false, error: (error as Error).message });
  }
});

export default router;