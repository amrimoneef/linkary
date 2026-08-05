class MacFilterEntity {
  final String filterMode; // 'disable', 'deny', 'allow'
  final List<String> allowList;
  final List<String> denyList;
  final String routerMac;

  MacFilterEntity({
    required this.filterMode,
    required this.allowList,
    required this.denyList,
    required this.routerMac,
  });
}