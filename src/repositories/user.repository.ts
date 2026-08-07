import { pool } from '../config/database';
import { UserRole } from '../constants/roles.enum';

export class UserRepository {
  static async findByEmail(email: string) {
    const query = `SELECT * FROM users WHERE email = $1;`;
    const result = await pool.query(query, [email]);
    return result.rows[0] || null;
  }

  static async createUser(firstName: string, lastName: string, email: string, passwordHash: string, role: UserRole = UserRole.MEMBER) {
    const query = `
      INSERT INTO users (first_name, last_name, email, password_hash, role)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, first_name, last_name, email, role, created_at;
    `;
    const values = [firstName, lastName, email, passwordHash, role];
    const result = await pool.query(query, values);
    return result.rows[0];
  }
}