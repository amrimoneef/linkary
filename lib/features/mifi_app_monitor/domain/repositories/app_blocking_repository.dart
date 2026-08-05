
import '../entities/blocked_app.dart';

abstract class AppBlockingRepository {
  // VPN Firewall Control
  Future<bool> prepareVpn();
  Future<bool> isFirewallRunning();
  Future<void> startFirewall(List<String> blockedPackages);
  Future<void> stopFirewall();
  Future<void> updateFirewall(List<String> blockedPackages);

  // Persistence
  Future<List<BlockedApp>> getBlockedApps();
  Future<void> saveBlockedApps(List<BlockedApp> apps);
  Future<void> setFirewallEnabled(bool enabled);
  Future<bool> getFirewallEnabled();
}
