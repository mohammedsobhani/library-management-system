import { BorrowRepository } from '../repositories/borrow.repository';
import { AppError } from '../errors/app-error';

export class BorrowService {
  static async checkout(userId: string, barcode: string) {
    if (!barcode) throw new AppError('Barcode is required for checkout', 400);
    try {
      return await BorrowRepository.checkoutBook(userId, barcode);
    } catch (err: any) {
      throw new AppError(err.message || 'Checkout failed', 400);
    }
  }

  static async return(borrowRecordId: string) {
    if (!borrowRecordId) throw new AppError('Borrow record ID is required', 400);
    try {
      return await BorrowRepository.returnBook(borrowRecordId);
    } catch (err: any) {
      throw new AppError(err.message || 'Return failed', 400);
    }
  }
}