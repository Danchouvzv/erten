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
                  _buildGrowthChart(context),
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

  Widget _buildGrowthChart(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionLabel('Trends'),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(),
            ),
          ),
        ],
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
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.4,
      size.width,
      size.height * 0.15,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..shader = const LinearGradient(
        colors: [
          AppColors.primaryOrange,
          AppColors.orangeSoft,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Gradient outline drop shadow effect for the line
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = AppColors.primaryOrange.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.drawPath(path, linePaint);

    // Glowing fill gradient under the line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryOrange.withOpacity(0.26),
          AppColors.primaryOrange.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
