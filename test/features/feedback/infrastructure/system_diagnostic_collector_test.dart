import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:linkary/features/feedback/infrastructure/services/system_diagnostic_collector.dart';
import 'package:linkary/features/modem_auth/presentation/controllers/auth_controller.dart';


// Mock AuthController if needed
class MockAuthController extends GetxController implements AuthController {
  @override
  var currentSN = RxnString();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('SystemDiagnosticCollector Model Tests', () {
    test('extracts first 3 chars from serial number prefixed with Sam4g', () async {
      final mockAuth = MockAuthController();
      mockAuth.currentSN.value = 'M56102345678';
      Get.put<AuthController>(mockAuth);

      final collector = SystemDiagnosticCollector();
      final diag = await collector.collectDiagnostics();

      expect(diag.modemModel, 'Sam4g M56');
    });

    test('extracts first 3 chars for M5010 router model', () async {
      final mockAuth = MockAuthController();
      mockAuth.currentSN.value = 'M5010987654';
      Get.put<AuthController>(mockAuth);

      final collector = SystemDiagnosticCollector();
      final diag = await collector.collectDiagnostics();

      expect(diag.modemModel, 'Sam4g M50');
    });

    test('returns غير متوفر when no SN or router is connected', () async {
      final collector = SystemDiagnosticCollector();
      final diag = await collector.collectDiagnostics();

      expect(diag.modemModel, 'غير متوفر');
    });
  });
}
