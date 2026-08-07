import { pool } from '../config/database';

export class LogRepository {
  static async createLog(userId: string | null, action: string, details?: string) {
    const query = `
      INSERT INTO system_logs (user_id, action, details)
      VALUES ($1, $2, $3)
      RETURNING *;
    `;
    const result = await pool.query(query, [userId, action, details || null]);
    return result.rows[0];
  }

  static async getLogs(limit: number = 20, offset: number = 0) {
    const query = `
      SELECT l.*, u.email as user_email, u.first_name, u.last_name
      FROM system_logs l
      LEFT JOIN users u ON l.user_id = u.id
      ORDER BY l.created_at DESC
      LIMIT $1 OFFSET $2;
    `;
    const result = await pool.query(query, [limit, offset]);
    return result.rows;
  }
}