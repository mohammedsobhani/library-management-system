import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../config/database';
import { env } from '../config/env';
const router = Router();

// ============================================================================
// 1. REGISTER STUDENT
// ============================================================================
router.post('/register', async (req: Request, res: Response): Promise<void> => {
    try {
        const { name, email, password } = req.body;

        if (!name || !email || !password) {
            res.status(400).json({
                success: false,
                message: 'Name, email, and password are required.',
            });
            return;
        }
        // Check if user already exists
        const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (existingUser.rows.length > 0) {
            res.status(409).json({
                success: false,
                message: 'User with this email already exists.',
            });
            return;
        }

        // Hash password before saving
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        const query = `
      INSERT INTO users (name, email, password, role)
      VALUES ($1, $2, $3, $4)
      RETURNING id, name, email, role, created_at;
    `;

        const result = await pool.query(query, [
            name,
            email,
            hashedPassword,
            'STUDENT',
        ]);

        res.status(201).json({
            success: true,
            message: 'User registered successfully!',
            data: result.rows[0],
        });
    } catch (error) {
        console.error('Error in /register:', error);
        res.status(500).json({
            success: false,
            error: (error as Error).message,
        });
    }
});

// ============================================================================
// 2. USER LOGIN (Bcrypt verification + dual-format payload)
// ============================================================================
router.post('/login', async (req: Request, res: Response): Promise<void> => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            res.status(400).json({
                success: false,
                message: 'Email and password are required.',
            });
            return;
        }

        // Fetch user record from database
        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

        if (result.rows.length === 0) {
            res.status(401).json({
                success: false,
                message: 'Invalid email or password.',
            });
            return;
        }

        const user = result.rows[0];

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            res.status(401).json({
                success: false,
                message: 'Invalid email or password.',
            });
            return;
        }

        // Sign JWT token using secret from env
        const token = jwt.sign(
            {
                id: user.id,
                userId: String(user.id),
                email: user.email,
                role: user.role,
            },
            env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        const userPayload = {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
        };

        // Return both top-level and nested 'data' objects to prevent Flutter null access errors
        res.status(200).json({
            success: true,
            message: 'Login successful!',
            token: token,
            user: userPayload,
            data: {
                token: token,
                user: userPayload,
            },
        });
    } catch (error) {
        console.error('Error in /login:', error);
        res.status(500).json({
            success: false,
            error: (error as Error).message,
        });
    }
});

// ============================================================================
// 3. GET CURRENT LOGGED-IN USER DETAILS (/me)
// ============================================================================
router.get('/me', async (req: Request, res: Response): Promise<void> => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({ success: false, message: 'Unauthorized access.' });
            return;
        }

        const token = authHeader.slice('Bearer '.length).trim();
        if (!token) {
            res.status(401).json({ success: false, message: 'Unauthorized access.' });
            return;
        }

        const decoded = jwt.verify(token, env.JWT_SECRET);
        if (
            typeof decoded === 'string' ||
            (typeof decoded.id !== 'string' && typeof decoded.id !== 'number')
        ) {
            res.status(401).json({ success: false, message: 'Invalid or expired token.' });
            return;
        }

        const userResult = await pool.query('SELECT id, name, email, role FROM users WHERE id = $1', [
            decoded.id,
        ]);

        if (userResult.rows.length === 0) {
            res.status(404).json({ success: false, message: 'User not found.' });
            return;
        }

        res.status(200).json({
            success: true,
            user: userResult.rows[0],
            data: userResult.rows[0],
        });
    } catch (error) {
        res.status(401).json({ success: false, message: 'Invalid or expired token.' });
    }
});

export default router;