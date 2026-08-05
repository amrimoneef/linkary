import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  AuthModel({
    required super.isAuthenticated,
    super.sessionId,
    super.isSetupRequired,
  });

// يمكننا هنا إضافة دوال fromJson إذا كانت الاستجابة معقدة
// لكن حالياً نحن نكتفي بتمرير القيم مباشرة إلى الكيان الأب
}