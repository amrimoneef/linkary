import '../entities/url_filter_entity.dart';
import '../repositories/url_filter_repository.dart';

class GetUrlFilterUseCase {
  final UrlFilterRepository repository;

  GetUrlFilterUseCase(this.repository);

  Future<UrlFilterEntity> call() async {
    return await repository.getUrlFilter();
  }
}
