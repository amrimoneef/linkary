import 'package:get/get.dart';
import '../../../../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';

class ModemSessionService {
  /// Safely retrieves the current modem uptime.
  /// First attempts to get it from DashboardController if registered,
  /// otherwise returns 0 (until a direct API call method is implemented).
  int getCurrentModemUptime() {
    try {
      if (Get.isRegistered<DashboardController>() && Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.currentUser == null) return 0; // Don't awake Dashboard if not logged in
        
        final dash = Get.find<DashboardController>();
        return dash.dashboardData.value?.currentDuration ?? 0;
      }
    } catch (e) {
      // Avoid crashing if DashboardController is being deleted or re-initialized
    }
    return 0;
  }

  /// Detects if the modem has been restarted by comparing current uptime with last recorded uptime.
  bool hasModemRestarted(int currentUptime, int lastUptime) {
    // If current uptime is less than saved, it's a clear indicator of a reboot/reset
    return lastUptime > 0 && currentUptime > 0 && currentUptime < lastUptime;
  }
}
