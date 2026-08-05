import 'package:flutter/services.dart';

class FirewallNativeDataSource {
  static const _channel = MethodChannel('com.linkary.mifi/firewall');

  Future<bool> prepareVpn() async {
    try {
      return await _channel.invokeMethod('prepareVpn') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> startFirewall(List<String> apps) async {
    await _channel.invokeMethod('startFirewall', {'apps': apps});
  }

  Future<void> updateFirewall(List<String> apps) async {
    await _channel.invokeMethod('updateFirewall', {'apps': apps});
  }

  Future<void> stopFirewall() async {
    await _channel.invokeMethod('stopFirewall');
  }

  Future<bool> isFirewallActive() async {
    try {
      return await _channel.invokeMethod('isFirewallActive') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
