import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { AppError } from '../errors/app-error';
import { UserRole } from '../constants/roles.enum';

// Define JwtPayload interface directly
export interface JwtPayload {
  userId: string;
  email: string;
  role: UserRole;
}

export const authenticateJWT = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new AppError('Authentication token required', 401));
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as JwtPayload;
    req.user = decoded;
    next();
  } catch (err) {
    return next(new AppError('Invalid or expired authentication token', 401));
  }
};

export const authorizeRoles = (...allowedRoles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new AppError('User context missing', 401));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(new AppError('Access forbidden: Insufficient permissions', 403));
    }

    next();
  };
};