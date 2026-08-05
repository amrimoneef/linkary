import '../../domain/entities/url_filter_entity.dart';
import '../../domain/repositories/url_filter_repository.dart';
import '../data_sources/url_filter_remote_data_source.dart';

class UrlFilterRepositoryImpl implements UrlFilterRepository {
  final UrlFilterRemoteDataSource remoteDataSource;

  UrlFilterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UrlFilterEntity> getUrlFilter() async {
    return await remoteDataSource.fetchUrlFilterData();
  }

  @override
  Future<bool> saveUrlFilter({required String mode, required List<String> blackItems}) async {
    return await remoteDataSource.saveUrlFilter(mode, blackItems);
  }
}
