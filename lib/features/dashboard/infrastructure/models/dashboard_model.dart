import '../../domain/entities/dashboard_entity.dart';

class DashboardModel extends DashboardEntity {
  DashboardModel({
    required super.networkType,
    required super.signalLevel,
    required super.rssi,
    required super.ipv4Ip,
    required super.networkName,
    required super.batteryCapacity,
    required super.isCharging,
    required super.phoneNumber,
    required super.imei,
    required super.txSpeed,
    required super.rxSpeed,
    required super.currentDuration,
    required super.totalDuration,
    required super.currentUsage,
    required super.totalUsage,
    required super.isDataConnected,
  });

  // دالة مصنع (Factory) لتحويل الـ JSON المعقد إلى كائن Dart نظيف
  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    if (json['responses'] == null) {
      throw Exception('المودم رفض الطلب: $json');
    }
    try {
      // 1. الوصول إلى الرد الأول الخاص بـ get_link_context
      final data = json['responses'][0]['data'];

      // 2. تفكيك الكائنات الداخلية بأمان (استخدام Map فارغ كبديل لتجنب أخطاء Null)
      final cellular = data['celluar_basic_info'] ?? {};
      final signal = data['signal_info'] ?? {};
      final contextList = data['contextlist'] as List?;
      final batteryData = json['responses'][2]['data'] ?? {};
      final context = (contextList != null && contextList.isNotEmpty) ? contextList[0] : {};
      final phoneData = json['responses'][3]['data'] ?? {};
      final trafficData =  json['responses'][4]['data']?['traffic_transport_status'] ?? {};
      final statsData = json['responses'][5]['data']?['statistics'] ?? {};
      
      // محاولة استخراج معلومات الجهاز (قد يكون غير موجود في بعض المودمات)
      final deviceInfo = (json['responses'].length > 6) ? (json['responses'][6]['data'] ?? {}) : {};

      return DashboardModel(
        networkType: signal['rat'] ?? 'Unknown',
        signalLevel: signal['level'] ?? 0,
        rssi: cellular['rssi'] ?? 0,
        networkName: cellular['network_name'] ?? 'Unknown',
        ipv4Ip: context['ipv4_ip'] ?? '0.0.0.0',
        batteryCapacity: batteryData['capacity'] ?? 0,
        isCharging: batteryData['status'] == 1,
        phoneNumber: phoneData['phone_no'] ?? 'غير متوفر',
        imei: cellular['IMEI']?.toString() ?? cellular['imei']?.toString() ?? deviceInfo['imei']?.toString() ?? '',
        txSpeed: trafficData['tx_status'] ?? 0,
        rxSpeed: trafficData['rx_status'] ?? 0,
        currentDuration: statsData['duration'] ?? 0,
        totalDuration: statsData['total_duration'] ?? 0,
        currentUsage: statsData['rx_tx_bytes'] ?? 0,
        totalUsage: statsData['total_rx_tx_bytes'] ?? 0,
        isDataConnected: context['c_status'] == 1 || (context['ipv4_ip'] != null && context['ipv4_ip'] != '0.0.0.0'),
      );
    } catch (e) {
      throw Exception('فشل في تحليل بيانات لوحة التحكم: $e');
    }
  }
}