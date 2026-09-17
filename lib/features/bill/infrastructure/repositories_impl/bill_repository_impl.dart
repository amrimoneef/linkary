import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../data_sources/bill_remote_data_source.dart';
import '../data_sources/bill_api_data_source.dart';
import '../services/bill_config_service.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource remoteDataSource;
  final BillApiDataSource? apiDataSource;
  final BillConfigService configService;

  BillRepositoryImpl({
    required this.remoteDataSource,
    this.apiDataSource,
    required this.configService,
  });

  @override
  Future<BillEntity> fetchBill(String phoneNumber) async {
    final config = await configService.getConfig();

    // نتحقق أولاً مما إذا كان البروكسي السحابي مفعلاً في الإعدادات
    if (config.enableRemoteProxy && apiDataSource != null) {
      try {
        if (kDebugMode) print('🌐 [BillRepository] Attempting inquiry via Remote API...');
        return await apiDataSource!.fetchBill(phoneNumber);
      } on CaptchaRequiredException {
        rethrow;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [BillRepository] Remote API failed ($e). Falling back to direct scraping...');
        }
        return await remoteDataSource.fetchBill(phoneNumber);
      }
    }

    // الاستعلام المباشر من الهاتف عبر الإعدادات الديناميكية (سريع وغير محظور جغرافياً)
    return remoteDataSource.fetchBill(phoneNumber);
  }

  @override
  Future<BillEntity> submitBillWithCaptcha({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
  }) async {
    final config = await configService.getConfig();

    if (config.enableRemoteProxy && apiDataSource != null) {
      try {
        return await apiDataSource!.submitBillWithCaptcha(
          phone: phone,
          captchaCode: captchaCode,
          nonce: nonce,
          cookies: cookies,
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [BillRepository] Remote API submit failed ($e). Trying direct scraping submit...');
        }
        return await remoteDataSource.submitBillWithCaptcha(
          phone: phone,
          captchaCode: captchaCode,
          nonce: nonce,
          cookies: cookies,
        );
      }
    }

    return remoteDataSource.submitBillWithCaptcha(
      phone: phone,
      captchaCode: captchaCode,
      nonce: nonce,
      cookies: cookies,
    );
  }
}

