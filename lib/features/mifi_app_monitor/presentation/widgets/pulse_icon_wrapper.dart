import 'package:flutter/material.dart';

class PulseIconWrapper extends StatefulWidget {
  final Widget child;
  final Color pulseColor;
  final bool isActive;

  const PulseIconWrapper({
    super.key,
    required this.child,
    required this.pulseColor,
    this.isActive = false,
  });

  @override
  State<PulseIconWrapper> createState() => _PulseIconWrapperState();
}

class _PulseIconWrapperState extends State<PulseIconWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulseIconWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 Fix: Use a fixed SizedBox (icon size = 50x50).
    // The Stack overflows visually only — it does NOT push or disturb
    // neighbouring list items because the SizedBox preserves the layout slot.
    const double iconSize = 50.0;
    const double maxRingRadius = 32.0; // how much the ring grows beyond the icon edge

    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            // clipBehavior: none lets rings bleed outside without affecting layout
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Pulse rings — positioned absolutely, centred on the icon
              if (widget.isActive)
                ...List.generate(2, (index) {
                  final double delay = index * 0.5;
                  final double progress = (_controller.value + delay) % 1.0;
                  final double ringSize = iconSize + (progress * maxRingRadius * 2);

                  return Positioned(
                    // Centre the ring regardless of its size
                    left: (iconSize - ringSize) / 2,
                    top: (iconSize - ringSize) / 2,
                    child: Opacity(
                      opacity: (1.0 - progress) * 0.55,
                      child: Container(
                        width: ringSize,
                        height: ringSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.pulseColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              // The actual icon sits on top of the rings
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
