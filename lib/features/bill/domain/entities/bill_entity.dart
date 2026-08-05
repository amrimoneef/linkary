class BillEntity {
  /// بيانات الفاتورة كـ Map مرن (لأن الحقول تتغير حسب الباقة)
  final Map<String, String> data;

  const BillEntity({required this.data});

  bool get isEmpty => data.isEmpty;
}
