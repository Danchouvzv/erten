import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../main.dart';
import '../ui_kit.dart';
import 'premium.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 22),
                  _buildIdentityCard(context, appState),
                  const SizedBox(height: 18),
                  _buildSummaryGrid(context, appState),
                  const SizedBox(height: 26),
                  _buildIdentitySystem(context, appState),
                  const SizedBox(height: 26),
                  _buildContractAndFailures(context, appState),
                  const SizedBox(height: 26),
                  _buildMetricCard(context, appState),
                  const SizedBox(height: 26),
                  _buildMilestones(context, appState),
                  const SizedBox(height: 26),
                  _buildPremiumCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Profile',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 38,
                  letterSpacing: -0.8,
                ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.elevatedBlack,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primaryOrange,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityCard(BuildContext context, AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.elevatedBlack,
            AppColors.cardBlack,
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.07),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF151517),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryOrange,
                  size: 44,
                ),
              ),
              Positioned(
                right: -1,
                bottom: 5,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryOrange,
                    border: Border.all(color: AppColors.cardBlack, width: 3),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.backgroundBlack,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danial Talgatov',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 25,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Level ${state.level} strategist',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.72),
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPill('Lvl ${state.level}'),
                    _buildPill(
                      '${(state.completionRate * 100).toInt()}% today',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, AppState state) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryTile(
            context,
            icon: Icons.check_circle_rounded,
            value: state.totalTasksCompleted.toString(),
            label: 'Blocks',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryTile(
            context,
            icon: Icons.bolt_rounded,
            value: '${(state.executionScore * 100).toInt()}%',
            label: 'Execute',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryTile(
            context,
            icon: Icons.radar_rounded,
            value: '${(state.completionRate * 100).toInt()}%',
            label: 'Today',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTile(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 19),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 27,
                  letterSpacing: -0.5,
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
    );
  }

  Widget _buildMetricCard(BuildContext context, AppState state) {
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionLabel('Health Metrics'),
          const SizedBox(height: 22),
          _buildMetricRow(
            context,
            'Discipline',
            'Daily structure',
            state.disciplineScore,
            Icons.self_improvement_rounded,
          ),
          _buildDivider(),
          _buildMetricRow(
            context,
            'Execution',
            'Blocks finished',
            state.executionScore,
            Icons.bolt_rounded,
          ),
          _buildDivider(),
          _buildMetricRow(
            context,
            'Focus',
            'Attention quality',
            state.focusScore,
            Icons.visibility_rounded,
          ),
          _buildDivider(),
          _buildMetricRow(
            context,
            'Consistency',
            'Current rhythm',
            state.progressPercent == 0 ? 0.88 : state.progressPercent,
            Icons.calendar_month_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySystem(BuildContext context, AppState state) {
    final badges = state.earnedBadges;
    return AppPanel(
      padding: const EdgeInsets.all(22),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionLabel('Identity'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildIdentityStat(
                  context,
                  'Current Streak',
                  '${state.currentStreak}',
                  'days',
                  Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIdentityStat(
                  context,
                  'Best Streak',
                  '${state.bestStreak}',
                  'days',
                  Icons.emoji_events_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: (badges.isEmpty ? ['First badge pending'] : badges)
                .map((badge) => _buildBadgeChip(badge, badges.isNotEmpty))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityStat(
    BuildContext context,
    String title,
    String value,
    String suffix,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevatedBlack,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 22),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 32),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  suffix,
                  style: const TextStyle(
                    color: AppColors.labelGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.labelGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String label, bool earned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: earned
            ? AppColors.primaryOrange.withOpacity(0.14)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: earned
              ? AppColors.primaryOrange.withOpacity(0.24)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            earned ? Icons.military_tech_rounded : Icons.lock_rounded,
            color: earned ? AppColors.primaryOrange : AppColors.labelGray,
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: earned ? AppColors.textWhite : AppColors.labelGray,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractAndFailures(BuildContext context, AppState state) {
    return AppPanel(
      padding: const EdgeInsets.all(22),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionLabel('Execution Contract'),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _contractColor(state.contractStatus).withOpacity(0.13),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _contractColor(state.contractStatus).withOpacity(0.24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _contractIcon(state.contractStatus),
                      color: _contractColor(state.contractStatus),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _contractLabel(state.contractStatus),
                      style: TextStyle(
                        color: _contractColor(state.contractStatus),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  state.executionContract.isEmpty
                      ? 'Accept a plan to create today’s contract.'
                      : state.executionContract,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPatternTile(
                  'Top failure',
                  state.topFailureReason,
                  Icons.psychology_alt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPatternTile(
                  'Reasons logged',
                  state.failureReasons.values
                      .fold<int>(0, (a, b) => a + b)
                      .toString(),
                  Icons.analytics_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.elevatedBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 19),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.labelGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _contractColor(String status) {
    switch (status) {
      case 'fulfilled':
        return AppColors.secondaryTeal;
      case 'partial':
        return AppColors.orangeSoft;
      case 'broken':
        return Colors.redAccent;
      case 'active':
        return AppColors.primaryOrange;
      default:
        return AppColors.labelGray;
    }
  }

  IconData _contractIcon(String status) {
    switch (status) {
      case 'fulfilled':
        return Icons.verified_rounded;
      case 'partial':
        return Icons.timelapse_rounded;
      case 'broken':
        return Icons.warning_rounded;
      case 'active':
        return Icons.edit_document;
      default:
        return Icons.note_alt_outlined;
    }
  }

  String _contractLabel(String status) {
    switch (status) {
      case 'fulfilled':
        return 'Fulfilled';
      case 'partial':
        return 'Partially fulfilled';
      case 'broken':
        return 'Broken';
      case 'active':
        return 'Active';
      default:
        return 'No contract';
    }
  }

  Widget _buildMetricRow(
    BuildContext context,
    String title,
    String subtitle,
    double value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.labelGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: value.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56, top: 14, bottom: 14),
      child: Container(
        height: 1,
        color: Colors.white.withOpacity(0.065),
      ),
    );
  }

  Widget _buildMilestones(BuildContext context, AppState state) {
    final stages = [
      const _Stage('Observer', true, false, false),
      const _Stage('Initiate', true, false, false),
      _Stage('Executor', false, state.level < 7, false),
      _Stage(
        'Builder',
        false,
        state.level >= 7 && state.level < 12,
        state.level < 7,
      ),
      _Stage('Elite', false, state.level >= 12, state.level < 12),
    ];

    final progressWidth = state.level >= 12
        ? 0.94
        : state.level >= 7
            ? 0.68
            : 0.46;

    return AppPanel(
      padding: const EdgeInsets.all(22),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AppSectionLabel('Milestones')),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Level ${state.level}',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 92,
                child: Stack(
                  children: [
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 19,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 19,
                      child: Container(
                        width: constraints.maxWidth * progressWidth,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: stages.map(_buildStageNode).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          Text(
            'Your execution history shapes the next stage.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.58),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageNode(_Stage stage) {
    final isBright = stage.isCompleted || stage.isCurrent;
    final nodeColor = stage.isCurrent
        ? AppColors.primaryOrange
        : isBright
            ? Colors.white
            : Colors.white.withOpacity(0.18);

    return SizedBox(
      width: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: stage.isCurrent ? 38 : 32,
            height: stage.isCurrent ? 38 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stage.isCurrent
                  ? AppColors.primaryOrange
                  : AppColors.elevatedBlack,
              border: Border.all(
                color: nodeColor,
                width: stage.isCurrent ? 0 : 1.5,
              ),
              boxShadow: stage.isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.42),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              stage.isLocked
                  ? Icons.lock_rounded
                  : stage.isCompleted
                      ? Icons.check_rounded
                      : Icons.circle_rounded,
              color: stage.isCurrent ? AppColors.backgroundBlack : nodeColor,
              size: stage.isCurrent ? 18 : 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stage.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: nodeColor,
              fontSize: 11,
              fontWeight: stage.isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C2018),
            AppColors.cardBlack,
          ],
        ),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sharper prediction and deeper insights.',
                      style: TextStyle(
                        color: AppColors.labelGray,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Open Premium',
            icon: Icons.arrow_forward_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Stage {
  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;

  const _Stage(this.label, this.isCompleted, this.isCurrent, this.isLocked);
}
