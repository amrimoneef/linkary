import '../entities/banner_entity.dart';
import '../repositories/banners_repository.dart';

class GetBannersUseCase {
  final BannersRepository repository;

  GetBannersUseCase({required this.repository});

  Future<List<BannerEntity>> execute() async {
    return await repository.getBanners();
  }
}
