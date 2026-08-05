class AdminSettingsModel {
  final String username;
  final String password;
  final String totalTime;
  final int sleepTime;
  final String lcdPassword;
  final String simcardType;

  AdminSettingsModel({
    required this.username,
    required this.password,
    required this.totalTime,
    required this.sleepTime,
    required this.lcdPassword,
    required this.simcardType,
  });

  factory AdminSettingsModel.fromJson(Map<String, dynamic> json) {
    final responses = json['responses'] as List;
    
    final accountData = responses[0]['data'] ?? {};
    final sleepData = responses[1]['data'] ?? {};
    final simData = responses[2]['data'] ?? {};
    final lcdData = responses[3]['data'] ?? {};

    return AdminSettingsModel(
      username: accountData['username'] ?? '',
      password: accountData['password'] ?? '',
      totalTime: accountData['total_time'] ?? '0',
      sleepTime: sleepData['result'] ?? 0,
      simcardType: simData['simcard_type'] ?? '',
      lcdPassword: lcdData['lcd_pw'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'totalTime': totalTime,
      'sleepTime': sleepTime,
      'lcdPassword': lcdPassword,
      'simcardType': simcardType,
    };
  }
}
