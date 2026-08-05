import 'package:get/get.dart';
import '../../domain/entities/saved_location.dart';
import '../../infrastructure/services/saved_locations_service.dart';

class SavedLocationsController extends GetxController {
  final SavedLocationsService _service;

  SavedLocationsController(this._service);

  final RxList<SavedLocation> locations = <SavedLocation>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadLocations();
  }

  Future<void> loadLocations() async {
    isLoading.value = true;
    try {
      final list = await _service.getSavedLocations();
      locations.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveLocation(SavedLocation location) async {
    final success = await _service.addLocation(location);
    if (success) {
      await loadLocations();
    }
    return success;
  }

  Future<void> replaceLocation(String oldLocationId, SavedLocation newLocation) async {
    await _service.replaceLocation(oldLocationId, newLocation);
    await loadLocations();
  }

  Future<void> deleteLocation(String id) async {
    await _service.deleteLocation(id);
    await loadLocations();
  }
}
