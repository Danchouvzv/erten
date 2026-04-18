import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../main.dart';
import '../ui_kit.dart';

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelay,
  });

  final TaskBlock task;
  final VoidCallback onComplete;
  final VoidCallback onDelay;

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen>
    with SingleTickerProviderStateMixin {
  late final Timer _timer;
  late final AnimationController _pulseController;
  DateTime _now = DateTime.now();

  String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining(widget.task.endTime);
    final progress = _progress(widget.task);

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          const AppBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white54),
                      ),
                      const Spacer(),
                      FadeTransition(
                        opacity: _pulseController,
                        child: const Text(
                          'Focus',
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${widget.task.startTime} - ${widget.task.endTime}',
                    style: TextStyle(
                      color: AppColors.primaryOrange.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.task.title,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 34,
                      fontWeight: FontWeight.w200,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 42),
                  Center(
                    child: Text(
                      remaining,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 58,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primaryOrange),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No context switching. Finish the block, then move.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.34),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          'Delay 10m',
                          Icons.snooze_rounded,
                          () {
                            widget.onDelay();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPrimaryButton(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onComplete();
        Navigator.pop(context);
      },
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withOpacity(0.25),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Done',
          style: TextStyle(
            color: AppColors.backgroundBlack,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.elevatedBlack,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _progress(TaskBlock task) {
    try {
      final start = _minutes(task.startTime);
      final end = _minutes(task.endTime);
      final now = _now.hour * 60 + _now.minute;
      return ((now - start) / (end - start)).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  String _remaining(String endTime) {
    try {
      final end = _minutes(endTime);
      final diff = end - (_now.hour * 60 + _now.minute);
      if (diff <= 0) return '00:00';
      return '${_pad(diff ~/ 60)}:${_pad(diff % 60)}';
    } catch (_) {
      return '--:--';
    }
  }

  int _minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
