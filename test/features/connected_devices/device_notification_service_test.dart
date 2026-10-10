import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/connected_devices/infrastructure/services/device_notification_service.dart';

void main() {
  group('DeviceNotificationService Payload & Action Tests', () {
    test('encodePayload and parsePayload work symmetrically', () {
      final payload = DeviceNotificationService.encodePayload(
        mac: '00:11:22:33:44:55',
        deviceName: 'iPhone 15 Pro',
        sn: 'SN998877',
      );

      final data = DeviceNotificationService.parsePayload(payload);
      expect(data['mac'], '00:11:22:33:44:55');
      expect(data['name'], 'iPhone 15 Pro');
      expect(data['sn'], 'SN998877');
      expect(data['type'], DeviceNotificationService.payloadType);
    });

    test('extractActionType separates action and mac correctly', () {
      expect(
        DeviceNotificationService.extractActionType(DeviceNotificationService.actionBlock),
        'block',
      );
      expect(
        DeviceNotificationService.extractActionType(DeviceNotificationService.actionTrust),
        'trust',
      );
      expect(
        DeviceNotificationService.extractActionType(DeviceNotificationService.actionDismiss),
        'dismiss',
      );
    });

    test('getNotificationId generates consistent stable ID for MAC', () {
      const mac1 = 'AA:BB:CC:DD:EE:FF';
      const mac2 = '11:22:33:44:55:66';

      final id1a = DeviceNotificationService.getNotificationId(mac1);
      final id1b = DeviceNotificationService.getNotificationId(mac1);
      final id2 = DeviceNotificationService.getNotificationId(mac2);

      expect(id1a, id1b);
      expect(id1a != id2, true);
    });
  });
}
