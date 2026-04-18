import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';
import '../ui_kit.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final List<String> _features = [
    'Advanced AI prediction models',
    'Long-term trajectory simulation',
    'Full behavioral enforcement',
    'Biometric focus sync',
    'Elite network access'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          const AppBackdrop(intense: true),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Material(
                            color: Colors.white.withOpacity(0.05),
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.all(14),
                                child: Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const AppBadge(
                          label: 'Elite',
                          icon: Icons.workspace_premium_rounded),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppPanel(
                          accent: true,
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppBadge(
                                  label: 'Premium Layer',
                                  icon: Icons.auto_awesome_rounded),
                              const SizedBox(height: 22),
                              Text(
                                'Upgrade your planning, focus, and recovery loop.',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(fontSize: 32, height: 1.04),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Adaptive re-routing, deeper debriefs, and long-term progress patterns.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.68),
                                      height: 1.55,
                                    ),
                              ),
                              const SizedBox(height: 26),
                              _buildPriceCard(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const AppSectionLabel('What You Unlock'),
                        const SizedBox(height: 18),
                        ...List.generate(_features.length,
                            (i) => _buildFeatureItem(_features[i], i)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: _buildStickyCTA(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppPanel(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.primaryOrange.withOpacity(0.15),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.primaryOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppColors.elevatedBlack,
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lifetime',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.primaryOrange)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\$',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white.withOpacity(0.52))),
              Text('99',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(fontSize: 50)),
              Text('.99',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white.withOpacity(0.52))),
            ],
          ),
          const SizedBox(height: 12),
          Text('One-time purchase',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.42))),
        ],
      ),
    );
  }

  Widget _buildStickyCTA() {
    return AppPrimaryButton(
      label: 'Authorize Upgrade',
      icon: Icons.lock_open_rounded,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Initializing payment gateway...'),
          ),
        );
      },
    );
  }
}
