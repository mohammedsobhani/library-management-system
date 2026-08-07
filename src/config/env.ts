import dotenv from 'dotenv';
import path from 'path';
import { z } from 'zod';

// 1. Force dotenv to load the .env file from your project root FIRST
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

// 2. Define what variables MUST exist
const envSchema = z.object({
  PORT: z.string().default('10000'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),
  JWT_SECRET: z.string().min(32, "JWT_SECRET must be at least 32 characters long"),
  JWT_EXPIRES_IN: z.string().default('1d'),
});

// 3. Check process.env against the schema above
export const env = envSchema.parse(process.env);