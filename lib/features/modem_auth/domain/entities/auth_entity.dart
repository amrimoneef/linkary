class AuthEntity {
  final bool isAuthenticated;
  final String? sessionId;
  final bool isSetupRequired;

  AuthEntity({
    required this.isAuthenticated,
    this.sessionId,
    this.isSetupRequired = false,
  });
}