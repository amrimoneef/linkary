import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  // حقن الاعتمادية (Dependency Injection) عبر الـ Constructor
  LoginUseCase(this.repository);

  // دالة التنفيذ
  Future<AuthEntity> execute(String password) async {
    // يمكننا هنا وضع أي منطق أعمال (Business Logic)
    // مثلاً: التحقق من أن كلمة المرور ليست فارغة قبل إرسالها للمستودع
    if (password.trim().isEmpty) {
      throw Exception('كلمة المرور لا يمكن أن تكون فارغة');
    }

    return await repository.login(password);
  }
}