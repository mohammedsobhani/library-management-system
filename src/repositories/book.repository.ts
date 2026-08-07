import { pool } from '../config/database';

export class BookRepository {
  static async createCategory(name: string, description?: string) {
    const query = `
      INSERT INTO categories (name, description)
      VALUES ($1, $2)
      RETURNING *;
    `;
    const result = await pool.query(query, [name, description || null]);
    return result.rows[0];
  }

  static async createAuthor(name: string, bio?: string) {
    const query = `
      INSERT INTO authors (name, bio)
      VALUES ($1, $2)
      RETURNING *;
    `;
    const result = await pool.query(query, [name, bio || null]);
    return result.rows[0];
  }

  static async createBook(isbn: string, title: string, categoryId: string, publishedYear?: number, publisher?: string) {
    const query = `
      INSERT INTO books (isbn, title, category_id, published_year, publisher)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `;
    const result = await pool.query(query, [isbn, title, categoryId, publishedYear || null, publisher || null]);
    return result.rows[0];
  }

  static async addBookCopy(bookId: string, barcode: string) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const copyQuery = `
        INSERT INTO book_copies (book_id, barcode, status)
        VALUES ($1, $2, 'AVAILABLE')
        RETURNING *;
      `;
      const copyResult = await client.query(copyQuery, [bookId, barcode]);

      const updateBookQuery = `
        UPDATE books 
        SET total_copies = total_copies + 1, updated_at = CURRENT_TIMESTAMP
        WHERE id = $1;
      `;
      await client.query(updateBookQuery, [bookId]);

      await client.query('COMMIT');
      return copyResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async getAllBooks(search?: string, limit: number = 10, offset: number = 0) {
    let query = `
      SELECT b.*, c.name as category_name
      FROM books b
      JOIN categories c ON b.category_id = c.id
    `;
    const values: any[] = [];

    if (search) {
      query += ` WHERE b.title ILIKE $1 OR b.isbn ILIKE $1`;
      values.push(`%${search}%`);
      query += ` ORDER BY b.created_at DESC LIMIT $2 OFFSET $3;`;
      values.push(limit, offset);
    } else {
      query += ` ORDER BY b.created_at DESC LIMIT $1 OFFSET $2;`;
      values.push(limit, offset);
    }

    const result = await pool.query(query, values);
    return result.rows;
  }
}