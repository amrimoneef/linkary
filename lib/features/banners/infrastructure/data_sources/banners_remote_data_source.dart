import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banner_model.dart';

class BannersRemoteDataSource {
  final http.Client client;

  BannersRemoteDataSource({required this.client});

  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await client.get(
        Uri.parse('https://sam4g.com/api/agent/banners?app=settings_app'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final bodyString = response.body.trim();
        
        // التحقق مما إذا كانت الاستجابة صفحة HTML (مثل بوابة عبور / Captive Portal)
        if (bodyString.startsWith('<')) {
           throw Exception('لا يوجد اتصال فعلي بالإنترنت (Captive Portal).');
        }

        final Map<String, dynamic> jsonResponse = json.decode(bodyString);
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => BannerModel.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load banners');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
