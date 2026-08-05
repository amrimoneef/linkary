import '../../domain/entities/blocked_app.dart';
import '../../domain/repositories/app_blocking_repository.dart';
import '../data_sources/blocked_apps_storage.dart';
import '../data_sources/firewall_native_data_source.dart';

class AppBlockingRepositoryImpl implements AppBlockingRepository {
  final FirewallNativeDataSource nativeSource;
  final BlockedAppsStorage storage;

  AppBlockingRepositoryImpl({
    required this.nativeSource,
    required this.storage,
  });

  @override
  Future<bool> isFirewallRunning() => nativeSource.isFirewallActive();

  @override
  Future<bool> prepareVpn() => nativeSource.prepareVpn();

  @override
  Future<void> startFirewall(List<String> blockedPackages) async {
    await nativeSource.startFirewall(blockedPackages);
  }

  @override
  Future<void> stopFirewall() async {
    await nativeSource.stopFirewall();
  }

  @override
  Future<void> updateFirewall(List<String> blockedPackages) async {
    await nativeSource.updateFirewall(blockedPackages);
  }

  @override
  Future<List<BlockedApp>> getBlockedApps() => storage.getBlockedApps();

  @override
  Future<void> saveBlockedApps(List<BlockedApp> apps) => storage.saveBlockedApps(apps);

  @override
  Future<bool> getFirewallEnabled() => storage.getFirewallEnabled();

  @override
  Future<void> setFirewallEnabled(bool enabled) => storage.setFirewallEnabled(enabled);
}
