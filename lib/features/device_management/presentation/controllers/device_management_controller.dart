import 'package:get/get.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../../../device_data_limit/presentation/controllers/device_data_limit_controller.dart';
import '../../../parental_control/presentation/controllers/parental_control_controller.dart';
import '../../../speed_limit/presentation/controllers/speed_limit_controller.dart';
import '../models/managed_device.dart';

class DeviceManagementController extends GetxController {
  final ParentalControlController parentalCtrl = Get.find<ParentalControlController>();
  final SpeedLimitController speedCtrl = Get.find<SpeedLimitController>();
  final DeviceDataLimitController dataLimitCtrl = Get.find<DeviceDataLimitController>();
  final ConnectedDevicesController devicesCtrl = Get.find<ConnectedDevicesController>();

  var isLoading = true.obs;
  var managedDevices = <ManagedDevice>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    try {
      // Fetch all data sequentially to prevent router overload (Connection reset by peer)
      await parentalCtrl.fetchData(silent: true);
      await speedCtrl.fetchData();
      await dataLimitCtrl.fetchData(silent: true);
      await devicesCtrl.fetchDevices();
      _buildManagedDevices();
    } catch (e) {
      // Errors should be handled by individual controllers (SessionHelper, etc.)
    } finally {
      isLoading.value = false;
    }
  }

  void _buildManagedDevices() {
    final List<ManagedDevice> result = [];
    
    // We use the connected devices as the base list
    for (var device in devicesCtrl.devices) {
      final macUpper = device.mac.toUpperCase();
      
      // Find parental rule
      final parentalDevice = parentalCtrl.devicesList.firstWhereOrNull(
        (d) => d.mac.toUpperCase() == macUpper,
      );

      // Find speed rule
      final speedRule = speedCtrl.deviceItems.firstWhereOrNull(
        (d) => d.ip == device.ip, // Speed limit uses IP currently
      );

      // Find data limit rule
      final dataLimit = dataLimitCtrl.deviceLimits.firstWhereOrNull(
        (d) => d.mac.toUpperCase() == macUpper,
      );

      result.add(ManagedDevice(
        mac: device.mac,
        name: devicesCtrl.getDisplayName(device),
        ip: device.ip,
        type: device.type,
        timeSlots: parentalDevice?.timeSlots,
        speedRule: speedRule,
        dataLimit: dataLimit,
      ));
    }

    managedDevices.value = result;
  }
  
  // -- Toggles --
  Future<void> toggleParentalControl(bool value) async {
    await parentalCtrl.toggleParentalControl(value);
    // UI reflects parentalCtrl.isEnabled
  }

  Future<void> toggleSpeedLimit(bool value) async {
    speedCtrl.isEnabled.value = value;
    await speedCtrl.saveData(closeOnSuccess: false);
  }

  Future<void> toggleDataLimit(bool value) async {
    await dataLimitCtrl.toggleEnable(value);
  }
}
