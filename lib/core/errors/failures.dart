abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure([super.message = "حدث خطأ أثناء الاتصال بالخادم."]);
}

class CacheFailure extends Failure {
  CacheFailure([super.message = "حدث خطأ في الذاكرة المؤقتة."]);
}

class SessionFailure extends Failure {
  SessionFailure([super.message = "انتهت الجلسة، يرجى تسجيل الدخول مجدداً."]);
}

class NetworkFailure extends Failure {
  NetworkFailure([super.message = "لا يوجد اتصال بالشبكة."]);
}
