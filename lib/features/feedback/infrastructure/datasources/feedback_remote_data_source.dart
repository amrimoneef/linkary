import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/feedback_submission.dart';

class FeedbackRemoteDataSource {
  static const String defaultEndpoint = 'https://www.sam4g.com/api/feedback/app-settings';
  static const String _signatureSalt = 'linkary_mobile_feedback_secure_salt_2026';

  final http.Client client;
  final String endpoint;

  FeedbackRemoteDataSource({
    http.Client? client,
    this.endpoint = defaultEndpoint,
  }) : client = client ?? http.Client();

  /// Submits feedback to the remote sam4g API endpoint
  Future<String> sendFeedback(FeedbackSubmission submission) async {
    final uri = Uri.parse(endpoint);
    final request = http.MultipartRequest('POST', uri);

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final nonce = '${DateTime.now().microsecondsSinceEpoch}_${submission.id}';
    
    // Dynamic HMAC-SHA256 signature
    final hmac = Hmac(sha256, utf8.encode(_signatureSalt));
    final signaturePayload = '$timestamp:$nonce:${uri.path}';
    final signature = hmac.convert(utf8.encode(signaturePayload)).toString();

    // Security & Platform headers
    request.headers.addAll({
      'User-Agent': 'Settings-App/1.0.3',
      'X-Timestamp': timestamp.toString(),
      'X-Request-Nonce': nonce,
      'X-App-Signature': signature,
      'X-App-Package': 'com.sam4g.app_settings',
      'Accept': 'application/json',
    });

    // Form fields
    request.fields['category'] = submission.category.id;
    request.fields['title'] = submission.title.trim();
    request.fields['description'] = submission.description.trim();
    if (submission.contactInfo != null && submission.contactInfo!.trim().isNotEmpty) {
      request.fields['contact_info'] = submission.contactInfo!.trim();
    }
    request.fields['include_diagnostics'] = submission.includeDiagnostics.toString();

    // Diagnostics if allowed
    if (submission.includeDiagnostics && submission.diagnosticInfo != null) {
      final diag = submission.diagnosticInfo!;
      request.fields['app_version'] = diag.appVersion;
      request.fields['device_model'] = diag.deviceModel;
      request.fields['os_version'] = diag.osVersion;
      request.fields['modem_model'] = diag.modemModel;
      request.fields['modem_firmware'] = diag.modemFirmware;
      request.fields['network_type'] = diag.networkType;
      request.fields['battery_level'] = diag.batteryLevel;
      request.fields['signal_strength'] = diag.signalStrength;
    }

    // Optional Screenshot attachment
    if (submission.attachmentPath != null && submission.attachmentPath!.isNotEmpty) {
      final file = File(submission.attachmentPath!);
      if (await file.exists()) {
        final multipartFile = await http.MultipartFile.fromPath(
          'attachment',
          file.path,
        );
        request.files.add(multipartFile);
      }
    }

    // Send with 12s timeout
    final streamedResponse = await request.send().timeout(const Duration(seconds: 12));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
        return bodyJson['message'] as String? ?? 'تم إرسال اقتراحك بنجاح';
      } catch (_) {
        return 'تم إرسال اقتراحك بنجاح';
      }
    } else {
      String errMsg = 'تعذر إرسال الاقتراح (رمز ${response.statusCode})';
      try {
        final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
        if (bodyJson.containsKey('errors') && bodyJson['errors'] is Map) {
          final errorsMap = bodyJson['errors'] as Map<String, dynamic>;
          final firstVal = errorsMap.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            errMsg = firstVal.first.toString();
          } else if (firstVal is String) {
            errMsg = firstVal;
          }
        } else if (bodyJson.containsKey('message')) {
          errMsg = bodyJson['message'] as String;
        }
      } catch (_) {}
      debugPrint('❌ [FeedbackRemoteDataSource] Error (${response.statusCode}): $errMsg');
      throw HttpException(errMsg);
    }
  }
}
