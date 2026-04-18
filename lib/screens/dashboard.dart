import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../app_state.dart';
import '../ui_kit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          const AppBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  _buildMainGoalCard(context, appState),
                  const SizedBox(height: 28),
                  _buildMetricsSection(context, appState),
                  const SizedBox(height: 28),
                  _buildGrowthChart(context, appState),
                  const SizedBox(height: 28),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final formatted =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Your day, focus, and progress at a glance.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.62),
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const AppBadge(
                label: 'Today', icon: Icons.local_fire_department_rounded),
            const SizedBox(height: 10),
            Text(
              formatted,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainGoalCard(BuildContext context, AppState appState) {
    final directive =
        appState.primaryDirective == 'NONE' || appState.primaryDirective.isEmpty
            ? 'Set a sharp directive and let the day build around it.'
            : appState.primaryDirective;

    return AppPanel(
      accent: true,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBadge(label: 'Pinned', icon: Icons.pin_rounded),
          const SizedBox(height: 22),
          Text(
            directive,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(height: 1.15),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day Progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.56),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(appState.progressPercent * 100).toInt()}%',
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(fontSize: 52),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: appState.progressPercent,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.primaryOrange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ArcProgress(
                value: appState.completionRate == 0
                    ? appState.progressPercent
                    : appState.completionRate,
                label: 'Focus',
                subtitle: 'Live score',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionLabel('Metrics'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
                child: _buildMetricCard(context, 'Discipline',
                    appState.disciplineScore, Icons.self_improvement_rounded)),
            const SizedBox(width: 14),
            Expanded(
                child: _buildMetricCard(context, 'Execution',
                    appState.executionScore, Icons.bolt_rounded)),
            const SizedBox(width: 14),
            Expanded(
                child: _buildMetricCard(context, 'Focus', appState.focusScore,
                    Icons.visibility_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      BuildContext context, String label, double value, IconData icon) {
    return AppPanel(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 22),
          const SizedBox(height: 18),
          Text(
            '${(value * 100).toInt()}%',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.58),
                ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: value,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation(
                AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(BuildContext context, AppState appState) {
    final tasks = List<TaskBlock>.from(appState.dailyTasks)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final completed = tasks.where((t) => t.isCompleted).length;
    final skipped = tasks.where((t) => t.isSkipped).length;
    final pending = tasks.where((t) => !t.isClosed).length;
    final chartData = _DayChartData.fromTasks(tasks, DateTime.now());

    return AppPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionLabel('Today Timeline'),
          const SizedBox(height: 18),
          if (tasks.isEmpty)
            _buildEmptyChart(context)
          else ...[
            Row(
              children: [
                _buildChartStat(
                    context, '$completed', 'done', AppColors.secondaryTeal),
                const SizedBox(width: 12),
                _buildChartStat(
                    context, '$skipped', 'skipped', AppColors.orangeSoft),
                const SizedBox(width: 12),
                _buildChartStat(
                    context, '$pending', 'left', AppColors.labelGray),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _ChartPainter(data: chartData),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  chartData.startLabel,
                  style: const TextStyle(
                    color: AppColors.labelGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  chartData.endLabel,
                  style: const TextStyle(
                    color: AppColors.labelGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.elevatedBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No timeline yet',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Generate a plan to see real progress across your day.',
                  style: TextStyle(
                    color: AppColors.labelGray,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartStat(
      BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.elevatedBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontSize: 25,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.labelGray,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionLabel('Actions'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
                child: _buildActionBtn(context, Icons.calendar_today_rounded,
                    'Plan', 'See today', () => onNavigate?.call(2))),
            const SizedBox(width: 14),
            Expanded(
                child: _buildActionBtn(
                    context,
                    Icons.auto_awesome_rounded,
                    'Design',
                    'Build a sharper routine',
                    () => onNavigate?.call(1))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, IconData icon, String label,
      String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AppPanel(
        radius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 28),
            const SizedBox(height: 18),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.54),
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.data});

  final _DayChartData data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.points.isEmpty) return;

    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 10.0;
    const bottomPad = 24.0;
    final chart = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );

    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.075)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chart.top + chart.height * (i / 3);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), basePaint);
    }

    final nowX = chart.left + chart.width * data.nowPosition;
    final nowPaint = Paint()
      ..color = AppColors.primaryOrange.withOpacity(0.28)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(nowX, chart.top), Offset(nowX, chart.bottom), nowPaint);

    final path = Path();
    for (var i = 0; i < data.points.length; i++) {
      final point = data.points[i];
      final offset = _offsetFor(point, chart);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..shader = const LinearGradient(
        colors: [
          AppColors.primaryOrange,
          AppColors.orangeSoft,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = AppColors.primaryOrange.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path)
      ..lineTo(_offsetFor(data.points.last, chart).dx, chart.bottom)
      ..lineTo(_offsetFor(data.points.first, chart).dx, chart.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryOrange.withOpacity(0.26),
          AppColors.primaryOrange.withOpacity(0.0),
        ],
      ).createShader(chart);

    canvas.drawPath(fillPath, fillPaint);

    for (final point in data.points) {
      final offset = _offsetFor(point, chart);
      final color = point.statusColor;
      canvas.drawCircle(
        offset,
        7,
        Paint()..color = color.withOpacity(0.18),
      );
      canvas.drawCircle(
        offset,
        4.2,
        Paint()..color = color,
      );
    }

    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'now',
        style: TextStyle(
          color: AppColors.primaryOrange,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset((nowX - labelPainter.width / 2).clamp(chart.left, chart.right),
          chart.bottom + 8),
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }

  Offset _offsetFor(_DayChartPoint point, Rect chart) {
    final x = chart.left + chart.width * point.x;
    final y = chart.bottom - chart.height * point.y;
    return Offset(x, y);
  }
}

class _DayChartData {
  const _DayChartData({
    required this.points,
    required this.nowPosition,
    required this.startLabel,
    required this.endLabel,
  });

  final List<_DayChartPoint> points;
  final double nowPosition;
  final String startLabel;
  final String endLabel;

  factory _DayChartData.fromTasks(List<TaskBlock> tasks, DateTime now) {
    if (tasks.isEmpty) {
      return const _DayChartData(
        points: [],
        nowPosition: 0,
        startLabel: '',
        endLabel: '',
      );
    }

    final start = _minutes(tasks.first.startTime);
    final end = _minutes(tasks.last.endTime);
    final span = (end - start).abs() <= 0 ? 1 : end - start;
    var closed = 0;
    final points = <_DayChartPoint>[
      const _DayChartPoint(x: 0, y: 0, status: _PointStatus.pending),
    ];

    for (final task in tasks) {
      if (task.isClosed) closed++;
      final taskEnd = _minutes(task.endTime);
      final x = ((taskEnd - start) / span).clamp(0.0, 1.0);
      final y = (closed / tasks.length).clamp(0.0, 1.0);
      final status = task.isCompleted
          ? _PointStatus.completed
          : task.isSkipped
              ? _PointStatus.skipped
              : _PointStatus.pending;
      points.add(_DayChartPoint(x: x, y: y, status: status));
    }

    final nowMinutes = now.hour * 60 + now.minute;
    final nowPosition = ((nowMinutes - start) / span).clamp(0.0, 1.0);

    return _DayChartData(
      points: points,
      nowPosition: nowPosition,
      startLabel: tasks.first.startTime,
      endLabel: tasks.last.endTime,
    );
  }

  static int _minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class _DayChartPoint {
  const _DayChartPoint({
    required this.x,
    required this.y,
    required this.status,
  });

  final double x;
  final double y;
  final _PointStatus status;

  Color get statusColor {
    switch (status) {
      case _PointStatus.completed:
        return AppColors.secondaryTeal;
      case _PointStatus.skipped:
        return AppColors.orangeSoft;
      case _PointStatus.pending:
        return AppColors.labelGray;
    }
  }
}

enum _PointStatus { completed, skipped, pending }
