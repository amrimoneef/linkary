import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/core/network/session_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('SessionManager Blocked MACs Tests', () {
    test('blockedMacs logic correctly saves and retrieves blocked MACs', () async {
      const testSn = 'TEST_SN_123';
      const mac = 'AA:BB:CC:DD:EE:02';

      await SessionManager.removeBlockedMac(mac, testSn);
      expect(await SessionManager.isDeviceBlocked(mac, testSn), false);

      await SessionManager.addBlockedMac(mac, testSn);
      expect(await SessionManager.isDeviceBlocked(mac, testSn), true);

      final list = await SessionManager.getBlockedMacs(testSn);
      expect(list.contains(mac), true);

      await SessionManager.removeBlockedMac(mac, testSn);
      expect(await SessionManager.isDeviceBlocked(mac, testSn), false);
    });
  });
}
