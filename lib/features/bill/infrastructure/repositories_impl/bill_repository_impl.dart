import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../data_sources/bill_remote_data_source.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource remoteDataSource;

  BillRepositoryImpl({required this.remoteDataSource});

  @override
  Future<BillEntity> fetchBill(String phoneNumber) {
    return remoteDataSource.fetchBill(phoneNumber);
  }

  @override
  Future<BillEntity> submitBillWithCaptcha({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
  }) {
    return remoteDataSource.submitBillWithCaptcha(
      phone: phone,
      captchaCode: captchaCode,
      nonce: nonce,
      cookies: cookies,
    );
  }
}
