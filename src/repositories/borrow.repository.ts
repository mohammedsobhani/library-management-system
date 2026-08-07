import { pool } from '../config/database';
import { LogRepository } from './log.repository';

export class BorrowRepository {
  static async checkoutBook(userId: string, barcode: string, daysToBorrow: number = 14) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Find book copy by barcode
      const copyResult = await client.query(
        `SELECT * FROM book_copies WHERE barcode = $1 FOR UPDATE;`,
        [barcode]
      );
      const copy = copyResult.rows[0];

      if (!copy) throw new Error('Book copy with this barcode not found.');
      if (copy.status !== 'AVAILABLE') throw new Error(`Book copy is currently ${copy.status}.`);

      // 2. Set due date
      const dueDate = new Date();
      dueDate.setDate(dueDate.getDate() + daysToBorrow);

      // 3. Create borrow record
      const borrowQuery = `
        INSERT INTO borrow_records (user_id, book_copy_id, due_date, status)
        VALUES ($1, $2, $3, 'ISSUED')
        RETURNING *;
      `;
      const borrowResult = await client.query(borrowQuery, [userId, copy.id, dueDate]);

      // 4. Update book copy status
      await client.query(
        `UPDATE book_copies SET status = 'BORROWED' WHERE id = $1;`,
        [copy.id]
      );

      // 5. Create System Log entry automatically
      await LogRepository.createLog(
        userId,
        'BOOK_CHECKOUT',
        `Checked out barcode: ${barcode}`
      );

      await client.query('COMMIT');
      return borrowResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async returnBook(borrowRecordId: string, dailyFineRate: number = 1.0) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Get borrow record
      const recordResult = await client.query(
        `SELECT * FROM borrow_records WHERE id = $1 FOR UPDATE;`,
        [borrowRecordId]
      );
      const record = recordResult.rows[0];

      if (!record) throw new Error('Borrow record not found.');
      if (record.status === 'RETURNED') throw new Error('Book has already been returned.');

      const returnDate = new Date();
      let fineAmount = 0;

      // Calculate fine if overdue
      if (returnDate > new Date(record.due_date)) {
        const diffTime = Math.abs(returnDate.getTime() - new Date(record.due_date).getTime());
        const overdueDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        fineAmount = overdueDays * dailyFineRate;
      }

      // 2. Update record status
      const updateRecordQuery = `
        UPDATE borrow_records 
        SET return_date = $1, status = 'RETURNED'
        WHERE id = $2
        RETURNING *;
      `;
      const updatedRecord = await client.query(updateRecordQuery, [returnDate, borrowRecordId]);

      // 3. Update copy status to AVAILABLE
      await client.query(
        `UPDATE book_copies SET status = 'AVAILABLE' WHERE id = $1;`,
        [record.book_copy_id]
      );

      // 4. Create fine entry if fine exists
      let fine = null;
      if (fineAmount > 0) {
        const fineQuery = `
          INSERT INTO fines (borrow_record_id, amount, status)
          VALUES ($1, $2, 'UNPAID')
          RETURNING *;
        `;
        const fineResult = await client.query(fineQuery, [borrowRecordId, fineAmount]);
        fine = fineResult.rows[0];
      }

      // 5. Create System Log entry automatically
      await LogRepository.createLog(
        record.user_id,
        'BOOK_RETURN',
        `Returned record ID: ${borrowRecordId}${fineAmount > 0 ? ` with fine $${fineAmount}` : ''}`
      );

      await client.query('COMMIT');
      return { borrowRecord: updatedRecord.rows[0], fine };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}