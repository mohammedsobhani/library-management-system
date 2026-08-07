import { Request, Response, NextFunction } from 'express';
import { LogRepository } from '../repositories/log.repository';

export class LogController {
  static async getLogs(req: Request, res: Response, next: NextFunction) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const offset = (page - 1) * limit;

      const logs = await LogRepository.getLogs(limit, offset);
      res.status(200).json({ success: true, data: logs });
    } catch (error) {
      next(error);
    }
  }
}