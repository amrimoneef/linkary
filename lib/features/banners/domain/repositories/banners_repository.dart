import '../entities/banner_entity.dart';

abstract class BannersRepository {
  Future<List<BannerEntity>> getBanners();
}
