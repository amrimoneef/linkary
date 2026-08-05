import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/saved_location.dart';
import 'dart:convert';

class SavedLocationsService {
  final FlutterSecureStorage _storage;
  static const String _storageKey = 'radar_saved_locations';
  static const int maxLocations = 10;

  SavedLocationsService(this._storage);

  Future<List<SavedLocation>> getSavedLocations() async {
    try {
      final data = await _storage.read(key: _storageKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = json.decode(data);
        final locations = decoded.map((e) => SavedLocation.fromMap(e)).toList();
        // Sort by timestamp descending (newest first)
        locations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return locations;
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  Future<void> saveLocations(List<SavedLocation> locations) async {
    final encoded = json.encode(locations.map((e) => e.toMap()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }

  Future<bool> addLocation(SavedLocation location) async {
    final currentList = await getSavedLocations();
    if (currentList.length >= maxLocations) {
      return false; // Limit reached, need to replace
    }
    currentList.insert(0, location);
    await saveLocations(currentList);
    return true;
  }

  Future<void> replaceLocation(String oldLocationId, SavedLocation newLocation) async {
    final currentList = await getSavedLocations();
    final index = currentList.indexWhere((loc) => loc.id == oldLocationId);
    if (index != -1) {
      currentList[index] = newLocation;
      // Sort again after replace
      currentList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await saveLocations(currentList);
    }
  }

  Future<void> deleteLocation(String locationId) async {
    final currentList = await getSavedLocations();
    currentList.removeWhere((loc) => loc.id == locationId);
    await saveLocations(currentList);
  }
}
