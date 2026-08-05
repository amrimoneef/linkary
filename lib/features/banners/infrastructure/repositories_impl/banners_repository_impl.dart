import '../../domain/entities/banner_entity.dart';
import '../../domain/repositories/banners_repository.dart';
import '../data_sources/banners_remote_data_source.dart';

class BannersRepositoryImpl implements BannersRepository {
  final BannersRemoteDataSource remoteDataSource;

  BannersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<BannerEntity>> getBanners() async {
    return await remoteDataSource.getBanners();
  }
}
