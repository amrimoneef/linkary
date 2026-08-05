import '../entities/url_filter_entity.dart';

abstract class UrlFilterRepository {
  Future<UrlFilterEntity> getUrlFilter();
  Future<bool> saveUrlFilter({required String mode, required List<String> blackItems});
}
