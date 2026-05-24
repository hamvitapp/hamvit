import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/hamvit_colors.dart';

class HamvitAnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  const HamvitAnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HamvitColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: HamvitColors.accentCyan),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class HamvitChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final String? subtitle;

  const HamvitChartCard({super.key, required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HamvitColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class HamvitStatTile extends StatelessWidget {
  final String label;
  final String value;

  const HamvitStatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class HamvitScoreWidget extends StatelessWidget {
  final double score;

  const HamvitScoreWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score.clamp(0, 100)) / 100;
    return Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: pct,
                strokeWidth: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(HamvitColors.accentMint),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(score.toStringAsFixed(0), style: Theme.of(context).textTheme.headlineSmall),
                  Text('HAMVIT Score', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HamvitHeatmap extends StatelessWidget {
  final List<int> values;

  const HamvitHeatmap({super.key, required this.values});

  Color _heatColor(int v) {
    if (v >= 80) return HamvitColors.accentGreen;
    if (v >= 60) return HamvitColors.accentMint;
    if (v >= 40) return HamvitColors.accentCyan;
    if (v >= 20) return HamvitColors.accentBlue;
    return Colors.white.withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values
          .map(
            (v) => Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _heatColor(v),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
          .toList(),
    );
  }
}

class HamvitProgressLine extends StatelessWidget {
  final String label;
  final double progress;

  const HamvitProgressLine({super.key, required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: progress.clamp(0, 1),
            color: HamvitColors.accentCyan,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class HamvitInsightCard extends StatelessWidget {
  final String title;
  final String body;
  final String severity;

  const HamvitInsightCard({super.key, required this.title, required this.body, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      'positive' => HamvitColors.accentMint,
      'warning' => HamvitColors.warning,
      _ => HamvitColors.accentBlue,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class HamvitReportPreview extends StatelessWidget {
  final String title;
  final String period;
  final String score;

  const HamvitReportPreview({
    super.key,
    required this.title,
    required this.period,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HamvitColors.primaryDark, HamvitColors.primaryNavy],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Periodo: $period', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('HAMVIT Score: $score', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class HamvitPdfViewer extends StatelessWidget {
  final Uint8List? bytes;

  const HamvitPdfViewer({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HamvitColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 42, color: HamvitColors.accentCyan),
          const SizedBox(height: 8),
          Text(
            bytes == null ? 'PDF ainda não gerado.' : 'PDF pronto para compartilhamento.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class HamvitShareSheet extends StatelessWidget {
  final VoidCallback? onShare;

  const HamvitShareSheet({super.key, this.onShare});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onShare,
      icon: const Icon(Icons.share_outlined),
      label: const Text('Compartilhar relatório'),
    );
  }
}
