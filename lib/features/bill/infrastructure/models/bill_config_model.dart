class BillConfigModel {
  final bool enableRemoteProxy;
  final String baseUrl;
  final String submitUrl;
  final String captchaUrl;
  final String referer;
  final String origin;
  final String nonceField;
  final String phoneField;
  final String captchaField;
  final String submitField;
  final String submitValue;
  final String queryBtnField;
  final String queryBtnValue;
  final String tableSelector;
  final String phoneErrorSelector;
  final String rateLimitKeyword;

  const BillConfigModel({
    this.enableRemoteProxy = false,
    required this.baseUrl,
    required this.submitUrl,
    required this.captchaUrl,
    required this.referer,
    required this.origin,
    required this.nonceField,
    required this.phoneField,
    required this.captchaField,
    required this.submitField,
    required this.submitValue,
    required this.queryBtnField,
    required this.queryBtnValue,
    required this.tableSelector,
    required this.phoneErrorSelector,
    required this.rateLimitKeyword,
  });

  /// الإعدادات الافتراضية المدمجة في التطبيق (Fallback في حال عدم توفر اتصال بسيرفرك)
  factory BillConfigModel.defaultValues() {
    return const BillConfigModel(
      enableRemoteProxy: false,
      baseUrl: 'https://svc.ptc.gov.ye/4g/',
      submitUrl: 'https://svc.ptc.gov.ye/4g/',
      captchaUrl:
          'https://svc.ptc.gov.ye/wp-content/plugins/query4g-bill-api/securimage/securimage_show.php?namespace=q4g_one_captcha',
      referer: '/4g/',
      origin: 'https://svc.ptc.gov.ye',
      nonceField: 'qb4g_nonce_field',
      phoneField: 'phone4gidnew',
      captchaField: 'captcha_code_q4Gbill',
      submitField: 'qb4g_submit',
      submitValue: 'YES',
      queryBtnField: 'qsubmitnew',
      queryBtnValue: 'استعلام',
      tableSelector: 'table.transdetail',
      phoneErrorSelector: '#phoneidrrornew',
      rateLimitKeyword: 'تجاوزت عدد مرات الاستعلام',
    );
  }

  factory BillConfigModel.fromJson(Map<String, dynamic> json) {
    final defaults = BillConfigModel.defaultValues();
    return BillConfigModel(
      enableRemoteProxy: json['enable_remote_proxy'] == true,
      baseUrl: json['base_url']?.toString() ?? defaults.baseUrl,
      submitUrl: json['submit_url']?.toString() ?? defaults.submitUrl,
      captchaUrl: json['captcha_url']?.toString() ?? defaults.captchaUrl,
      referer: json['referer']?.toString() ?? defaults.referer,
      origin: json['origin']?.toString() ?? defaults.origin,
      nonceField: json['nonce_field']?.toString() ?? defaults.nonceField,
      phoneField: json['phone_field']?.toString() ?? defaults.phoneField,
      captchaField: json['captcha_field']?.toString() ?? defaults.captchaField,
      submitField: json['submit_field']?.toString() ?? defaults.submitField,
      submitValue: json['submit_value']?.toString() ?? defaults.submitValue,
      queryBtnField: json['query_btn_field']?.toString() ?? defaults.queryBtnField,
      queryBtnValue: json['query_btn_value']?.toString() ?? defaults.queryBtnValue,
      tableSelector: json['table_selector']?.toString() ?? defaults.tableSelector,
      phoneErrorSelector:
          json['phone_error_selector']?.toString() ?? defaults.phoneErrorSelector,
      rateLimitKeyword:
          json['rate_limit_keyword']?.toString() ?? defaults.rateLimitKeyword,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_remote_proxy': enableRemoteProxy,
      'base_url': baseUrl,
      'submit_url': submitUrl,
      'captcha_url': captchaUrl,
      'referer': referer,
      'origin': origin,
      'nonce_field': nonceField,
      'phone_field': phoneField,
      'captcha_field': captchaField,
      'submit_field': submitField,
      'submit_value': submitValue,
      'query_btn_field': queryBtnField,
      'query_btn_value': queryBtnValue,
      'table_selector': tableSelector,
      'phone_error_selector': phoneErrorSelector,
      'rate_limit_keyword': rateLimitKeyword,
    };
  }
}
