import 'package:flutter/material.dart';
import 'dart:ui';

class MetricsMiniRow extends StatelessWidget {
  final String rawRsrp;
  final String rawSinr;
  final String rawRsrq;
  
  final double normRsrp;
  final double normSinr;
  final double normRsrq;

  const MetricsMiniRow({
    Key? key,
    required this.rawRsrp,
    required this.rawSinr,
    required this.rawRsrq,
    required this.normRsrp,
    required this.normSinr,
    required this.normRsrq,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('RSRP', rawRsrp, normRsrp)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricCard('SINR', rawSinr, normSinr)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricCard('RSRQ', rawRsrq, normRsrq)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String rawValue, double normValue) {
    final color = _getColor(normValue);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                rawValue.isEmpty ? '-' : rawValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: normValue / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(double normValue) {
    if (normValue == 0) return Colors.grey;
    if (normValue <= 25) return Colors.redAccent;
    if (normValue <= 50) return Colors.orangeAccent;
    if (normValue <= 79) return Colors.blueAccent;
    return Colors.greenAccent;
  }
}
