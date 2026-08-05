import '../entities/bill_entity.dart';

abstract class BillRepository {
  Future<BillEntity> fetchBill(String phoneNumber);
  Future<BillEntity> submitBillWithCaptcha({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
  });
}
