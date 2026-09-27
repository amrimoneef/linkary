import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/device_diagnostic_info.dart';

class DiagnosticInfoCard extends StatelessWidget {
  final bool isEnabled;
  final bool isExpanded;
  final DeviceDiagnosticInfo? diagnosticInfo;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onToggleExpanded;
  final bool isDark;

  const DiagnosticInfoCard({
    super.key,
    required this.isEnabled,
    required this.isExpanded,
    required this.diagnosticInfo,
    required this.onToggleEnabled,
    required this.onToggleExpanded,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // Switch header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.cpu, color: Color(0xFF3B82F6), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تضمين التشخيص الفني تلقائياً',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'يساعد المطور في حل المشكلة بمعرفة موديل الراوتر والنظام',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isEnabled,
                  activeThumbColor: const Color(0xFF4A90E2),
                  onChanged: onToggleEnabled,
                ),
              ],
            ),
          ),

          // Collapsible Details toggle
          if (isEnabled && diagnosticInfo != null) ...[
            Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            InkWell(
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isExpanded ? 'إخفاء التفاصيل الفنية المرفقة' : 'معاينة التفاصيل الفنية المرفقة (شفافية كاملة)',
                      style: const TextStyle(
                        color: Color(0xFF4A90E2),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF4A90E2),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDiagRow('طراز الهاتف', diagnosticInfo!.deviceModel),
                      _buildDiagRow('نظام التشغيل', diagnosticInfo!.osVersion),
                      _buildDiagRow('إصدار التطبيق', diagnosticInfo!.appVersion),
                      _buildDiagRow('طراز الراوتر', diagnosticInfo!.modemModel),
                      _buildDiagRow('السوفتوير', diagnosticInfo!.modemFirmware),
                      _buildDiagRow('نوع التغطية', diagnosticInfo!.networkType),
                      _buildDiagRow('البطارية', diagnosticInfo!.batteryLevel),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 11)),
          Text(value, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
