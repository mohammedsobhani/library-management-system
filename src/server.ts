import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import { pool } from './config/db';

// Import routes
import authRoutes from './routes/auth.routes';
import bookRoutes from './routes/book.routes';
import borrowRoutes from './routes/borrow.routes';
import logRoutes from './routes/log.routes';

const app = express();
const PORT = process.env.PORT || 10000;

// 🛑 CRITICAL CORS CONFIGURATION FOR FLUTTER WEB
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(cors());
app.use(express.json({ limit: '10mb' }));
// Mount routes
app.use('/auth', authRoutes);
app.use('/books', bookRoutes);
app.use('/borrow', borrowRoutes);
app.use('/logs', logRoutes);
async function startServer() {
  try {
    const client = await pool.connect();
    console.log('✅ Successfully connected to PostgreSQL database!');
    client.release();

    app.listen(PORT, () => {
      console.log(`🚀 Backend server running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('❌ Failed to start backend server:', error);
    process.exit(1);
  }
}
// Add this in src/server.ts BEFORE startServer()
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Cannot ${req.method} ${req.originalUrl} - Route not found on backend.`,
  });
});
startServer();