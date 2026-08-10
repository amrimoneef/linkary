import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.get(Uri.parse('http://192.168.8.1/api.cgi?path=router&method=get_guide_config'));
    print('RESPONSE BODY:');
    print(response.body);
  } catch (e) {
    print('Failed: $e');
  }
}
