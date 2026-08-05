import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

class FetchBillUseCase {
  final BillRepository repository;

  FetchBillUseCase(this.repository);

  Future<BillEntity> execute(String phoneNumber) {
    return repository.fetchBill(phoneNumber);
  }
}
