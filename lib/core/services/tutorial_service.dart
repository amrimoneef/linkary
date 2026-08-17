import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialService extends GetxService {
  late SharedPreferences prefs;

  // مفاتيح لوحة التحكم Dashboard
  final GlobalKey helpButtonKey = GlobalKey();
  final GlobalKey themeToggleKey = GlobalKey();
  final GlobalKey dataUsageCircleKey = GlobalKey();
  final GlobalKey qrCodeKey = GlobalKey();
  final GlobalKey connectedDevicesKey = GlobalKey();
  final GlobalKey speedsCardsKey = GlobalKey();
  final GlobalKey quickActionsKey = GlobalKey();
  final GlobalKey networkGridKey = GlobalKey();
  final GlobalKey signalBarsKey = GlobalKey();

  // مفاتيح شاشة الشبكة NetworkInfo
  final GlobalKey networkInfoHelpKey = GlobalKey();
  final GlobalKey radarButtonKey = GlobalKey();
  final GlobalKey speedTestButtonKey = GlobalKey();
  final GlobalKey smartAnalysisButtonKey = GlobalKey();
  final GlobalKey appMonitorButtonKey = GlobalKey();
  final GlobalKey modemFinderButtonKey = GlobalKey();
  final GlobalKey engineeringGridKey = GlobalKey();
  final GlobalKey bandLockCardKey = GlobalKey();

  // مفاتيح شاشة الإعدادات AllSettings
  final GlobalKey allSettingsHelpKey = GlobalKey();
  final GlobalKey powerCoreSwitchKey = GlobalKey();
  final GlobalKey rebootButtonKey = GlobalKey();
  final GlobalKey logoutButtonKey = GlobalKey();
  final GlobalKey settingsGridKey = GlobalKey();

  // مفاتيح شاشة إدارة الأجهزة DeviceManagement
  final GlobalKey deviceManagementHelpKey = GlobalKey();
  final GlobalKey dmStatsSummaryKey = GlobalKey();
  final GlobalKey dmMasterTogglesKey = GlobalKey();
  final GlobalKey dmRefreshButtonKey = GlobalKey();
  final GlobalKey dmDeviceCardKey = GlobalKey();

  // مفاتيح شاشة الرصيد Bill
  final GlobalKey billHelpKey = GlobalKey();
  final GlobalKey expectedBalanceKey = GlobalKey();
  final GlobalKey billRefreshButtonKey = GlobalKey();
  final GlobalKey billResultsKey = GlobalKey();

  // مفاتيح شاشة مراقب التطبيقات AppMonitor
  final GlobalKey appMonitorHelpKey = GlobalKey();
  final GlobalKey amExportButtonKey = GlobalKey();
  final GlobalKey amFirewallButtonKey = GlobalKey();
  final GlobalKey amResetButtonKey = GlobalKey();
  final GlobalKey amChartKey = GlobalKey();
  final GlobalKey amFilterBarKey = GlobalKey();
  final GlobalKey amSearchBarKey = GlobalKey();
  // final GlobalKey amStatusBannerKey = GlobalKey();
  final GlobalKey amSummaryCardKey = GlobalKey();
  final GlobalKey amLiveSpeedKey = GlobalKey();
  final GlobalKey amCategoryBreakdownKey = GlobalKey();

  // مفاتيح شاشة تفاصيل التطبيق AppDetail
  final GlobalKey appDetailHelpKey = GlobalKey();
  final GlobalKey adShareButtonKey = GlobalKey();
  final GlobalKey adMainStatsKey = GlobalKey();
  final GlobalKey adGridDetailsKey = GlobalKey();
  final GlobalKey adGoalButtonKey = GlobalKey();
  final GlobalKey adChartKey = GlobalKey();

  // مفاتيح الشريط السفلي والمساعد الصوتي
  final GlobalKey voiceAssistantKey = GlobalKey();
  final GlobalKey bottomNavKey = GlobalKey();

  bool _isShowing = false;
  int _currentIndex = 0;
  List<TargetFocus> _targets = [];

  void showDashboardTutorial(BuildContext context, {bool force = false}) async {
    if (_isShowing || (!force && (Get.isDialogOpen == true || Get.isBottomSheetOpen == true))) return;
    _isShowing = true;

    prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('has_seen_dashboard_tutorial') ?? false;

    if (!hasSeenTutorial || force) {
      _currentIndex = 0;
      _targets = (!hasSeenTutorial && !force) 
          ? _createHelpButtonHintTarget(helpButtonKey) 
          : _createDashboardTargets();
      
      // التمرير للعنصر الأول مباشرة قبل بدء الدرس
      _scrollToTarget(_targets[0].keyTarget);

      TutorialCoachMark(
        targets: _targets,
        colorShadow: const Color(0xFF0A0E21),
        textSkip: "إنهاء الآن",
        hideSkip: true,
        paddingFocus: 10,
        opacityShadow: 0.9,
        useSafeArea: true,
        onFinish: () {
          prefs.setBool('has_seen_dashboard_tutorial', true);
          _isShowing = false;
        },
        onClickTarget: (target) {
          _currentIndex++;
          if (_currentIndex < _targets.length) {
            _scrollToTarget(_targets[_currentIndex].keyTarget);
          }
        },
        onSkip: () {
          prefs.setBool('has_seen_dashboard_tutorial', true);
          _isShowing = false;
          return true;
        },
      ).show(context: context);
    } else {
      _isShowing = false;
    }
  }

  void showNetworkInfoTutorial(BuildContext context, {bool force = false}) async {
    if (_isShowing) return;
    _isShowing = true;

    prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('has_seen_network_info_tutorial') ?? false;

    if (!hasSeenTutorial || force) {
      _currentIndex = 0;
      _targets = (!hasSeenTutorial && !force) 
          ? _createHelpButtonHintTarget(networkInfoHelpKey) 
          : _createNetworkInfoTargets();
      
      _scrollToTarget(_targets[0].keyTarget);

      TutorialCoachMark(
        targets: _targets,
        colorShadow: const Color(0xFF0A0E21),
        textSkip: "إنهاء الدرس",
        paddingFocus: 10,
        opacityShadow: 0.9,
        useSafeArea: true,
        onFinish: () {
          prefs.setBool('has_seen_network_info_tutorial', true);
          _isShowing = false;
        },
        onClickTarget: (target) {
          _currentIndex++;
          if (_currentIndex < _targets.length) {
            _scrollToTarget(_targets[_currentIndex].keyTarget);
          }
        },
        onSkip: () {
          prefs.setBool('has_seen_network_info_tutorial', true);
          _isShowing = false;
          return true;
        },
      ).show(context: context);
    } else {
      _isShowing = false;
    }
  }

  void showAllSettingsTutorial(BuildContext context, {bool force = false}) async {
    if (_isShowing) return;
    _isShowing = true;

    prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('has_seen_all_settings_tutorial') ?? false;

    if (!hasSeenTutorial || force) {
      _currentIndex = 0;
      _targets = (!hasSeenTutorial && !force) 
          ? _createHelpButtonHintTarget(allSettingsHelpKey) 
          : _createAllSettingsTargets();
      
      _scrollToTarget(_targets[0].keyTarget);

      TutorialCoachMark(
        targets: _targets,
        colorShadow: const Color(0xFF0A0E21),
        textSkip: "إنهاء الدرس",
        paddingFocus: 10,
        opacityShadow: 0.9,
        useSafeArea: true,
        onFinish: () {
          prefs.setBool('has_seen_all_settings_tutorial', true);
          _isShowing = false;
        },
        onClickTarget: (target) {
          _currentIndex++;
          if (_currentIndex < _targets.length) {
            _scrollToTarget(_targets[_currentIndex].keyTarget);
          }
        },
        onSkip: () {
          prefs.setBool('has_seen_all_settings_tutorial', true);
          _isShowing = false;
          return true;
        },
      ).show(context: context);
    } else {
      _isShowing = false;
    }
  }

  void showBillTutorial(BuildContext context, {bool force = false}) async {
    if (_isShowing) return;
    _isShowing = true;

    prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('has_seen_bill_tutorial') ?? false;

    if (!hasSeenTutorial || force) {
      _currentIndex = 0;
      _targets = (!hasSeenTutorial && !force) 
          ? _createHelpButtonHintTarget(billHelpKey) 
          : _createBillTargets();
      
      _scrollToTarget(_targets[0].keyTarget);

      TutorialCoachMark(
        targets: _targets,
        colorShadow: const Color(0xFF0A0E21),
        textSkip: "إنهاء الدرس",
        paddingFocus: 10,
        opacityShadow: 0.9,
        useSafeArea: true,
        onFinish: () {
          prefs.setBool('has_seen_bill_tutorial', true);
          _isShowing = false;
        },
        onClickTarget: (target) {
          _currentIndex++;
          if (_currentIndex < _targets.length) {
            _scrollToTarget(_targets[_currentIndex].keyTarget);
          }
        },
        onSkip: () {
          prefs.setBool('has_seen_bill_tutorial', true);
          _isShowing = false;
          return true;
        },
      ).show(context: context);
    } else {
      _isShowing = false;
    }
  }

  void showAppMonitorTutorial(BuildContext context, {bool force = false}) async {
    if (_isShowing) return;
    _isShowing = true;

    prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('has_seen_app_monitor_tutorial') ?? false;

    if (!hasSeenTutorial || force) {
      _currentIndex = 0;
      _targets = (!hasSeenTutorial && !force)
          ? _createHelpButtonHintTarget(appMonitorHelpKey)
          : _createAppMonitorTargets();

      _scrollToTarget(_targets[0].keyTarget);

      TutorialCoachMark(
        targets: _targets,
        colorShadow: const Color(0xFF0A0E21),
        textSkip: "إنهاء الدرس",
        paddingFocus: 10,
        opacityShadow: 0.9,
        useSafeArea: true,
        onFinish: () {
          prefs.setBool('has_seen_app_monitor_tutorial', true);
          _isShowing = false;
        },
        onClickTarget: (target) {
          _currentIndex++;
          if (_currentIndex < _targets.length) {
            _scrollToTarget(_targets[_currentIndex].keyTarget);
          }
        },
        onSkip: () {
          prefs.setBool('has_seen_app_monitor_tutorial', true);
          _isShowing = false;
          return true;
        },
      ).show(context: context);
    } else {
      _isShowing = false;
    }
  }

  void showAppDetailTutorial(BuildContext context, {bool force = false}) async {
    if (_isShowing) return;
    _isShowing = true;

    prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('has_seen_app_detail_tutorial') ?? false;

    if (!hasSeenTutorial || force) {
      _currentIndex = 0;
      _targets = (!hasSeenTutorial && !force) 
          ? _createHelpButtonHintTarget(appDetailHelpKey) 
          : _createAppDetailTargets();
      
      _scrollToTarget(_targets[0].keyTarget);

      TutorialCoachMark(
        targets: _targets,
        colorShadow: const Color(0xFF0A0E21),
        textSkip: "إنهاء الآن",
        hideSkip: true,
        paddingFocus: 10,
        opacityShadow: 0.9,
        useSafeArea: true,
        onFinish: () {
          prefs.setBool('has_seen_app_detail_tutorial', true);
          _isShowing = false;
        },
        onClickTarget: (target) {
          _currentIndex++;
          if (_currentIndex < _targets.length) {
            _scrollToTarget(_targets[_currentIndex].keyTarget);
          }
        },
        onSkip: () {
          prefs.setBool('has_seen_app_detail_tutorial', true);
          _isShowing = false;
          return true;
        },
      ).show(context: context);
    } else {
      _isShowing = false;
    }
  }

  void showDeviceManagementTutorial(BuildContext context, {bool force = false}) async {
    if (_isShowing) return;
    _isShowing = true;

    prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('has_seen_device_management_tutorial') ?? false;

    if (!hasSeenTutorial || force) {
      _currentIndex = 0;
      _targets = (!hasSeenTutorial && !force) 
          ? _createHelpButtonHintTarget(deviceManagementHelpKey) 
          : _createDeviceManagementTargets();
      
      _scrollToTarget(_targets[0].keyTarget);

      TutorialCoachMark(
        targets: _targets,
        colorShadow: const Color(0xFF0A0E21),
        textSkip: "إنهاء الدرس",
        paddingFocus: 10,
        opacityShadow: 0.9,
        useSafeArea: true,
        onFinish: () {
          prefs.setBool('has_seen_device_management_tutorial', true);
          _isShowing = false;
        },
        onClickTarget: (target) {
          _currentIndex++;
          if (_currentIndex < _targets.length) {
            _scrollToTarget(_targets[_currentIndex].keyTarget);
          }
        },
        onSkip: () {
          prefs.setBool('has_seen_device_management_tutorial', true);
          _isShowing = false;
          return true;
        },
      ).show(context: context);
    } else {
      _isShowing = false;
    }
  }

  void _scrollToTarget(GlobalKey? key) {
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5, // لضمان ظهور العنصر في منتصف الشاشة تقريباً
        duration: Duration.zero, // بدون أنيميشن حتى يتم رسم الفقاعة بدقة
      );
    }
  }

  List<TargetFocus> _createDashboardTargets() {
    return [
      TargetFocus(
        identify: "ThemeToggle",
        keyTarget: themeToggleKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "تبديل المظهر",
              description: "يمكنك التبديل بين الوضع الليلي والنهاري بضغطة زر لراحة عينيك وتوفير الطاقة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "SignalBars",
        keyTarget: signalBarsKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "حالة الإشارة والبطارية",
              description: "مؤشر يوضح لك قوة إشارة الشبكة الحالية وحالة البطارية",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "DataUsageCircle",
        keyTarget: dataUsageCircleKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "استهلاك البيانات",
              description: "مؤشر ذكي يوضح لك النسبة المئوية لاستهلاك باقتك الحالية في الوقت الفعلي، يمكنك تحديد الباقة لاحقاً من الاعدادات.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "QrCode",
        keyTarget: qrCodeKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "مشاركة الشبكة بذكاء",
              description: "لا داعي لإعطاء كلمة المرور. اضغط هنا لإظهار رمز QR للضيوف للاتصال فوراً.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "ConnectedDevices",
        keyTarget: connectedDevicesKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "الأجهزة المتصلة",
              description: "تعرف على عدد الأجهزة المتصلة بشبكتك حالياً. يمكنك الضغط هنا لإدارة الأجهزة وحظر المتطفلين.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "SpeedsCards",
        keyTarget: speedsCardsKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "مراقبة السرعة",
              description: "تابع سرعة التنزيل والرفع المباشرة لضمان أفضل تجربة اتصال بالإنترنت.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "QuickActions",
        keyTarget: quickActionsKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "الوصول السريع للميزات",
              description: "اسحب يميناً ويساراً هنا للوصول السريع لجميع إعدادات المودم الهامة مثل الواي فاي، التحكم الأبوي، ومراقب التطبيقات.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "NetworkGrid",
        keyTarget: networkGridKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "تفاصيل الاستهلاك الشاملة",
              description: "قارن بين استهلاك الجلسة الحالية والاستهلاك الإجمالي لمعرفة نمط استخدامك للإنترنت.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "VoiceAssistant",
        keyTarget: voiceAssistantKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "المساعد الصوتي",
              description: "اضغط هنا للتحكم في المودم بصوتك! جرب أن تقول 'أظهر لي استهلاك البيانات' أو 'احظر جهاز؟'.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "BottomNav",
        keyTarget: bottomNavKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              isLast: true,
              title: "اكمل الدرس في شاشة الشبكة",
              description: "اضغط على أيقونة 'الشبكة' من هذا الشريط لننتقل معاً ونكمل درسنا حول أدوات الرادار والتحليل!",
            ),
          )
        ],
      ),
    ];
  }

  List<TargetFocus> _createNetworkInfoTargets() {
    return [
      TargetFocus(
        identify: "RadarButton",
        keyTarget: radarButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "تشغيل الرادار المتقدم",
              description: "أهلاً بك في قسم الشبكة! هنا يمكنك اكتشاف الامكان المناسبة كالمحترفين للحصول على أفضل إشارة للبرج.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "SmartAnalysis",
        keyTarget: smartAnalysisButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "التحليل الذكي",
              description: "أداة تقوم بفحص كامل لجودة الإشارة، التشويش، والنطاق، وتعطيك تقريراً ذكياً حول ما إذا كان اتصالك ممتازاً أم يحتاج تعديل.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "SpeedTest",
        keyTarget: speedTestButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "قياس السرعة",
              description: "لا داعي لتطبيقات خارجية! قم باختبار سرعة التنزيل والرفع بضغطة زر من داخل التطبيق.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AppMonitor",
        keyTarget: appMonitorButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "مراقب التطبيقات",
              description: "ميزة قوية وحصرية! تعرف على التطبيقات التي تستهلك الباقة على أجهزتك بشكل دقيق للتحكم بها و حظرها من استخدام الإنترنت.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "ModemFinder",
        keyTarget: modemFinderButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "أين المودم",
              description: "هل فقدت المودم؟ استخدم هذه الأداة للبحث عنه، أو فعل ميزة الحماية الاستباقية من الاعدادت لتنبيهك عند نسيانه.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "EngineeringGrid",
        keyTarget: engineeringGridKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(top: 120),
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "بيانات البرج الهندسية",
              description: "قراءات حية ومباشرة تشمل RSRP، SINR، والتردد المستخدم، تتحدث لحظياً لتساعدك في تتبع جودة الاستقبال.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "BandLockCard",
        keyTarget: bandLockCardKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(top: 120),
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              isLast: true,
              title: "تثبيت الترددات (Band Lock)",
              description: "التحكم المطلق! قم بدمج أو تثبيت ترددات معينة للبرج لتحسين سرعة الإنترنت لديك بكل سهولة وموثوقية. انتقل لتبويب الإعدادات أو الرصيد لإكمال الاكتشاف!",
            ),
          )
        ],
      ),
    ];
  }

  List<TargetFocus> _createAllSettingsTargets() {
    return [
      TargetFocus(
        identify: "PowerCoreSwitch",
        keyTarget: powerCoreSwitchKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "مفتاح بث الإنترنت",
              description: "من هنا يمكنك قطع أو تفعيل اتصال البيانات الخلوية للمودم بضغطة زر، لتوفير الباقة دون فصل الواي فاي عن الأجهزة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "SettingsGrid",
        keyTarget: settingsGridKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(top: 120),
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "مركز الإعدادات الشامل",
              description: "استكشف إعدادات متقدمة! من هنا تدير كلمة مرور الواي فاي، التحكم الأبوي، وحظر الأجهزة للحفاظ على أمان شبكتك.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "RebootButton",
        keyTarget: rebootButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "خيارات الطاقة",
              description: "إدارة طاقة المودم، اضغط هنا لإعادة تشغيل او إيقاف تشغيل المودم عن بُعد بكل سهولة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "LogoutButton",
        keyTarget: logoutButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              isLast: true,
              title: "تسجيل الخروج",
              description: "للحفاظ على أمان تطبيقك والمودم، يمكنك تسجيل الخروج من هنا فور انتهائك.",
            ),
          )
        ],
      ),
    ];
  }

  List<TargetFocus> _createBillTargets() {
    return [
      TargetFocus(
        identify: "ExpectedBalance",
        keyTarget: expectedBalanceKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "الرصيد المتاح المتوقع",
              description: "أداة ذكية وحصرية تحسب لك الرصيد المتبقي تقريبياً بالاعتماد على استخدامك حتى قبل إجراء الاستعلام الرسمي!",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "BillRefreshButton",
        keyTarget: billRefreshButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "استعلام فوري",
              description: "اضغط هنا لجلب تفاصيل فاتورتك الحقيقية من مزود الخدمة مباشرة. يمكنك تحديثها كل فترة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "BillResults",
        keyTarget: billResultsKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              isLast: true,
              title: "تفاصيل الفاتورة",
              description: "هنا ستظهر كل تفاصيل باقتك: الرصيد، الدقائق، وفترة الصلاحية بشكل مفصل وواضح.",
            ),
          )
        ],
      ),
    ];
  }

  List<TargetFocus> _createAppMonitorTargets() {
    return [
      TargetFocus(
        identify: "AmExportButton",
        keyTarget: amExportButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "مشاركة التقرير",
              description: "قم بتصدير تقرير استهلاكك اليومي أو الشهري كصورة انفوجرافيك جميلة لمشاركتها مع الآخرين أو حفظها.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AmFirewallButton",
        keyTarget: amFirewallButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "جدار الحماية (Firewall)",
              description: "إعدادات متقدمة لحظر التطبيقات من استخدام الإنترنت والتحكم الكامل في الوصول للشبكة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AmResetButton",
        keyTarget: amResetButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "تصفير الجلسة",
              description: "اضغط هنا لبدء حساب الاستهلاك من الصفر للوقت الحالي دون التأثير على بيانات الباقة الأساسية.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AmChart",
        keyTarget: amChartKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "الرسم البياني التفاعلي",
              description: "يعرض لك استهلاك البيانات (التنزيل والرفع) على مدار الأيام لمساعدتك في فهم نمط استخدامك.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AmFilterBar",
        keyTarget: amFilterBarKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "فلاتر العرض السريعة",
              description: "يمكنك تصفية عرض البيانات لتظهر لك تطبيقات النظام، الألعاب، السوشيال ميديا، أو حسب اليوم والشهر.",
            ),
          )
        ],
      ),
      // TargetFocus(
      //   identify: "AmStatusBanner",
      //   keyTarget: amStatusBannerKey,
      //   alignSkip: Alignment.bottomRight,
      //   shape: ShapeLightFocus.RRect,
      //   contents: [
      //     TargetContent(
      //       align: ContentAlign.top,
      //       builder: (context, controller) => _buildTutorialContent(
      //         controller: controller,
      //         title: "حالة المراقبة",
      //         description: "يوضح ما إذا كان المودم متصلاً وتطبيقك يتلقى البيانات المباشرة للاستهلاك.",
      //       ),
      //     )
      //   ],
      // ),
      TargetFocus(
        identify: "AmSummaryCard",
        keyTarget: amSummaryCardKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "إجمالي الاستهلاك",
              description: "ملخص يجمع لك حجم البيانات الكلي (تنزيل ورفع) التي تم استهلاكها في الجلسة أو الفترة المختارة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AmLiveSpeed",
        keyTarget: amLiveSpeedKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "السرعة اللحظية",
              description: "تابع سرعة نقل البيانات اللحظية لمعرفة حجم تدفق البيانات للتطبيقات الآن.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AmCategoryBreakdown",
        keyTarget: amCategoryBreakdownKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "تحليل الفئات",
              description: "رسم دائري يصنف لك الاستهلاك؛ لتعرف كم تستهلك الألعاب مقارنة بالتواصل الاجتماعي والنظام.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AmSearchBar",
        keyTarget: amSearchBarKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              isLast: true,
              title: "البحث السريع",
              description: "ابحث عن تطبيق معين لمعرفة استهلاكه بدقة. انقر على أي تطبيق في القائمة بالأسفل للدخول إلى تفاصيله المتقدمة!",
            ),
          )
        ],
      ),
    ];
  }

  List<TargetFocus> _createAppDetailTargets() {
    return [
      TargetFocus(
        identify: "AdShareButton",
        keyTarget: adShareButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "مشاركة التفاصيل",
              description: "قم بتصدير صورة جميلة توضح استهلاك هذا التطبيق المخصص لمشاركتها كتقرير.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AdMainStats",
        keyTarget: adMainStatsKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "تفاصيل الاستهلاك",
              description: "يعرض لك تفصيل دقيق لاستهلاك التطبيق مقسم إلى تنزيل ورفع، مع شريط تقدم يوضح مدى اقترابه من الحد المسموح.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AdGridDetails",
        keyTarget: adGridDetailsKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "معلومات متقدمة",
              description: "يوضح تصنيف التطبيق، آخر مرة كان نشطاً فيها، ومدة استخدامه الفعالة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AdGoalButton",
        keyTarget: adGoalButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "التحكم المطلق!",
              description: "من هنا يمكنك تعيين سقف (حد أقصى) للبيانات لهذا التطبيق، وسيقوم النظام بحظره تلقائياً عند التجاوز لتوفير الباقة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "AdChart",
        keyTarget: adChartKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              isLast: true,
              title: "الرسم البياني للتطبيق",
              description: "تابع تاريخ استهلاك هذا التطبيق تحديداً عبر الأيام لفهم متى يستهلك البيانات بشكل أكبر. انتهى الدرس المتقدم!",
            ),
          )
        ],
      ),
    ];
  }

  List<TargetFocus> _createDeviceManagementTargets() {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "DmStatsSummary",
        keyTarget: dmStatsSummaryKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "ملخص الأجهزة والقيود",
              description: "لوحة معلومات ذكية توضح عدد الأجهزة المتصلة حالياً بالشبكة وعدد الأجهزة المطبق عليها قيود الوقت، السرعة، وباقة البيانات.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "DmMasterToggles",
        keyTarget: dmMasterTogglesKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              title: "مفاتيح التحكم",
              description: "يمكنك تفعيل أو إيقاف أي ميزة (تخصيص الوقت، السرعة، الباقة، ومراقب الأجهزة الجديدة) بضغطة زر واحدة.",
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "DmRefreshButton",
        keyTarget: dmRefreshButtonKey,
        alignSkip: Alignment.bottomLeft,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              isLast: dmDeviceCardKey.currentContext == null,
              title: "تحديث قائمة الأجهزة",
              description: "اضغط هنا لإعادة فحص الشبكة فوراً وجلب أحدث الأجهزة المتصلة وقراءات استهلاكها الحية.",
            ),
          )
        ],
      ),
    ];

    if (dmDeviceCardKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "DmDeviceCard",
          keyTarget: dmDeviceCardKey,
          alignSkip: Alignment.bottomRight,
          shape: ShapeLightFocus.RRect,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => _buildTutorialContent(
                controller: controller,
                isLast: true,
                title: "تخصيص قواعد كل جهاز",
                description: "اضغط على أي جهاز متصل لفتح نافذة التحكم المتقدم: لتحديد باقة خاصة به، تقييد سرعته، جدول ساعات استخدامه، استخدم ايقونة الدرع لتوثيق الجهاز أو أسحب لليسار لحظره تماماً من الشبكة!",
              ),
            )
          ],
        ),
      );
    }

    return targets;
  }

  Widget _buildTutorialContent({
    required String title,
    required String description,
    required TutorialCoachMarkController controller,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 16.0,
              height: 1.6,
            ),
          ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => controller.skip(),
              child: Text(
                "إنهاء الآن",
                style: GoogleFonts.cairo(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                _currentIndex++;
                if (_currentIndex < _targets.length) {
                  _scrollToTarget(_targets[_currentIndex].keyTarget);
                }
                controller.next();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                elevation: 0,
              ),
              child: Text(
                isLast ? "فهمت" : "التالي",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    );
  }

  List<TargetFocus> _createHelpButtonHintTarget(GlobalKey key) {
    return [
      TargetFocus(
        identify: "HelpHint",
        keyTarget: helpButtonKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              controller: controller,
              isLast: true,
              title: "مركز المساعدة",
              description: "ستجد هذة الايقونة في اغلب الشاشات، يمكنك الضغط عليها لعرض تعليمات الاستخدام في اي وقت.",
            ),
          )
        ],
      )
    ];
  }
}
