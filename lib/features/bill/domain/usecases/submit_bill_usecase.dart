import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

class SubmitBillUseCase {
  final BillRepository repository;

  SubmitBillUseCase(this.repository);

  Future<BillEntity> execute({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
  }) {
    return repository.submitBillWithCaptcha(
      phone: phone,
      captchaCode: captchaCode,
      nonce: nonce,
      cookies: cookies,
    );
  }
}
