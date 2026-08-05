import 'dart:convert';

/// سكريبت مساعد لتحويل SHA-256 (بصيغة Hex) إلى Base64 
/// كما هو مطلوب في حزمة freeRASP.
/// 
/// طريقة الاستخدام في الـ Terminal:
/// dart run scripts/cert_hash.dart "قيمة_SHA_256_هنا"
void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ يرجى تمرير قيمة SHA-256. مثال:');
    print('dart run scripts/cert_hash.dart "FA:2A:..."');
    return;
  }

  String rawHash = args.first;
  
  // إزالة النقطتين (:) والمسافات
  String cleanHex = rawHash.replaceAll(':', '').replaceAll(' ', '').trim();
  
  if (cleanHex.length != 64) {
    print('❌ القيمة المدخلة غير صحيحة. يجب أن يكون طول SHA-256 هو 64 حرفاً (بدون النقطتين).');
    return;
  }

  try {
    // تحويل من Hex إلى Bytes
    List<int> bytes = [];
    for (int i = 0; i < cleanHex.length; i += 2) {
      String hexPair = cleanHex.substring(i, i + 2);
      bytes.add(int.parse(hexPair, radix: 16));
    }

    // تحويل Bytes إلى Base64
    String base64Hash = base64Encode(bytes);
    
    print('\n✅ التحويل ناجح!');
    print('--------------------------------------------------');
    print('انسخ هذا الكود وضعه في ملف app_security_service.dart:');
    print('\n$base64Hash\n');
    print('--------------------------------------------------');
    
  } catch (e) {
    print('❌ حدث خطأ أثناء التحويل: $e');
  }
}
