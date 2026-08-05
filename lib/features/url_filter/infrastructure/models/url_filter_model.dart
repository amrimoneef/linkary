import '../../domain/entities/url_filter_entity.dart';

class UrlFilterModel extends UrlFilterEntity {
  UrlFilterModel({
    required super.mode,
    required super.blackItems,
  });

  factory UrlFilterModel.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};
    final mode = settings['mode'] as String? ?? 'disable';
    
    // Extract non-empty black items
    final blackItemsRaw = settings['black_items'] as List<dynamic>? ?? [];
    List<String> blackItems = [];
    
    for (var item in blackItemsRaw) {
      if (item is Map<String, dynamic>) {
        final val = item['value'] as String?;
        if (val != null && val.isNotEmpty) {
          blackItems.add(val);
        }
      }
    }

    return UrlFilterModel(
      mode: mode,
      blackItems: blackItems,
    );
  }
}
