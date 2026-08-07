import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

import authRoutes from './routes/auth.routes';
import bookRoutes from './routes/book.routes';
import borrowRoutes from './routes/borrow.routes';
import logRoutes from './routes/log.routes';
import { errorHandler } from './middlewares/error.middleware';

const app: Application = express();

// 1. Enable CORS & explicit preflight handling FIRST
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Explicitly respond to preflight OPTIONS requests

// 2. Configure Helmet
app.use(
  helmet({
    crossOriginResourcePolicy: false,
    crossOriginOpenerPolicy: false,
  })
);

// 3. Body parser (Increased limit to 50mb for Base64 face image payloads)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
// 🛑 MAKE SURE THIS LINE IS PRESENT:
app.use('/api/borrow', borrowRoutes);
// 4. Rate Limiter (Skipped for preflight OPTIONS requests)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 500, // Increased limit for local development testing
  skip: (req) => req.method === 'OPTIONS', // Never rate-limit CORS preflight!
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// 5. Health Check
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
});

// 6. Bind API Routes (Both /api/v1 and fallback /api for complete compatibility)
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/books', bookRoutes);
app.use('/api/v1/borrow', borrowRoutes);
app.use('/api/v1/admin/logs', logRoutes);

// Fallback legacy bindings matching Flutter ApiService baseUrl
app.use('/api/auth', authRoutes);
app.use('/api/books', bookRoutes);
app.use('/api/borrow', borrowRoutes);

// 7. Global Error Handler (MUST BE LAST)
app.use(errorHandler);

export default app;