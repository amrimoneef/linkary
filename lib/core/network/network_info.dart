import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

abstract class NetworkInfo {
  Future<bool> isConnectedToModem();
}

class NetworkInfoImpl implements NetworkInfo {
  final http.Client client;

  NetworkInfoImpl(this.client);

  @override
  Future<bool> isConnectedToModem() async {
    try {
      final response = await client.get(
        Uri.parse(AppConstants.modemBaseUrl),
      ).timeout(const Duration(seconds: 1));
      
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      try {
        final socket = await Socket.connect('192.168.8.1', 80, timeout: const Duration(seconds: 1));
        socket.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
