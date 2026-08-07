import { Request, Response, NextFunction } from 'express';
import { BookService } from '../services/book.service';

export class BookController {
  static async createCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const { name, description } = req.body;
      const category = await BookService.addCategory(name, description);
      res.status(201).json({ success: true, data: category });
    } catch (error) {
      next(error);
    }
  }

  static async createAuthor(req: Request, res: Response, next: NextFunction) {
    try {
      const { name, bio } = req.body;
      const author = await BookService.addAuthor(name, bio);
      res.status(201).json({ success: true, data: author });
    } catch (error) {
      next(error);
    }
  }

  static async createBook(req: Request, res: Response, next: NextFunction) {
    try {
      const { isbn, title, categoryId, publishedYear, publisher } = req.body;
      const book = await BookService.addBook(isbn, title, categoryId, publishedYear, publisher);
      res.status(201).json({ success: true, data: book });
    } catch (error) {
      next(error);
    }
  }

  static async addCopy(req: Request, res: Response, next: NextFunction) {
    try {
      const { bookId, barcode } = req.body;
      const copy = await BookService.addBookCopy(bookId, barcode);
      res.status(201).json({ success: true, data: copy });
    } catch (error) {
      next(error);
    }
  }

  static async getBooks(req: Request, res: Response, next: NextFunction) {
    try {
      const search = req.query.search as string;
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;
      
      const books = await BookService.listBooks(search, page, limit);
      res.status(200).json({ success: true, data: books });
    } catch (error) {
      next(error);
    }
  }
}