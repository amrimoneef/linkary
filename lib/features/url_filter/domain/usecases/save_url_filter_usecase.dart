import '../repositories/url_filter_repository.dart';

class SaveUrlFilterUseCase {
  final UrlFilterRepository repository;

  SaveUrlFilterUseCase(this.repository);

  Future<bool> call({required String mode, required List<String> blackItems}) async {
    return await repository.saveUrlFilter(mode: mode, blackItems: blackItems);
  }
}
