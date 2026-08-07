import { BookRepository } from '../repositories/book.repository';
import { AppError } from '../errors/app-error';

export class BookService {
  static async addCategory(name: string, description?: string) {
    if (!name) throw new AppError('Category name is required', 400);
    return BookRepository.createCategory(name, description);
  }

  static async addAuthor(name: string, bio?: string) {
    if (!name) throw new AppError('Author name is required', 400);
    return BookRepository.createAuthor(name, bio);
  }

  static async addBook(isbn: string, title: string, categoryId: string, publishedYear?: number, publisher?: string) {
    if (!isbn || !title || !categoryId) {
      throw new AppError('ISBN, title, and categoryId are required fields', 400);
    }
    return BookRepository.createBook(isbn, title, categoryId, publishedYear, publisher);
  }

  static async addBookCopy(bookId: string, barcode: string) {
    if (!bookId || !barcode) throw new AppError('Book ID and barcode are required', 400);
    return BookRepository.addBookCopy(bookId, barcode);
  }

  static async listBooks(search?: string, page: number = 1, limit: number = 10) {
    const offset = (page - 1) * limit;
    return BookRepository.getAllBooks(search, limit, offset);
  }
}