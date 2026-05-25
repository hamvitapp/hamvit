import 'package:flutter/material.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../theme/hamvit_colors.dart';

class HamvitLegalSectionData {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const HamvitLegalSectionData({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

class HamvitLegalScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<HamvitLegalSectionData> sections;

  const HamvitLegalScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: HamvitColors.primaryDark,
      appBar: hamvitBackAppBar(context, title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(14, 12, 14, bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HamvitColors.primaryNavy.withValues(alpha: 0.98),
                      HamvitColors.darkCard.withValues(alpha: 0.98),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: HamvitColors.darkText,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HamvitColors.darkTextMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              for (final section in sections) ...[
                HamvitLegalSection(data: section),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HamvitLegalSection extends StatelessWidget {
  final HamvitLegalSectionData data;

  const HamvitLegalSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HamvitColors.darkCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HamvitColors.darkText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (data.paragraphs.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final paragraph in data.paragraphs) ...[
              Text(
                paragraph,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HamvitColors.darkText,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (data.bullets.isNotEmpty) ...[
            for (final item in data.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text(
                        '• ',
                        style: TextStyle(color: HamvitColors.accentCyan),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: HamvitColors.darkText,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
