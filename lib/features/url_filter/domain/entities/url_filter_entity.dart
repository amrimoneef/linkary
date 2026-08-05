class UrlFilterEntity {
  final String mode; // 'disable' or 'blacklist'
  final List<String> blackItems;

  UrlFilterEntity({
    required this.mode,
    required this.blackItems,
  });
}
