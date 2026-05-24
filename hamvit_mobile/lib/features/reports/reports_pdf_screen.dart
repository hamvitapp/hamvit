import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hamvit_date_utils.dart';
import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../../shared/widgets/hamvit_components.dart';
import 'reports_service.dart';
import 'widgets/hamvit_reports_widgets.dart';

class ReportsPdfScreen extends ConsumerStatefulWidget {
  final bool isPremium;
  const ReportsPdfScreen({super.key, required this.isPremium});

  @override
  ConsumerState<ReportsPdfScreen> createState() => _ReportsPdfScreenState();
}

class _ReportsPdfScreenState extends ConsumerState<ReportsPdfScreen> {
  List<int>? _pdfBytes;
  String? _reportId;
  String _message = '';

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(reportsServiceProvider);
    final profile = ref.watch(currentProfileProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HamvitHeader(title: 'PDF HAMVIT', subtitle: 'Exportacao com branding oficial e estrutura profissional.'),
        const SizedBox(height: 12),
        PremiumFeatureGate(
          feature: HamvitFeature.reportsPdfExport,
          isPremium: widget.isPremium,
          fallback: const PremiumTeaserCard(feature: HamvitFeature.reportsPdfExport),
          child: Column(
            children: [
              HamvitReportPreview(
                title: 'Relatório Semanal',
                period:
                    '${HamvitDateUtils.formatDateBr(DateTime.now().subtract(const Duration(days: 7)))} a ${HamvitDateUtils.formatDateBr(DateTime.now())}',
                score: '80',
              ),
              const SizedBox(height: 10),
              HamvitButton(
                label: 'Gerar PDF Premium',
                onPressed: () async {
                  final end = DateTime.now();
                  final start = end.subtract(const Duration(days: 7));
                  final result = await svc.createReport(start: start, end: end, premium: true, reportType: 'weekly');
                  final summary = (result?['summary'] as Map<String, dynamic>?) ?? {};
                  final insights = List<Map<String, String>>.from(result?['insights'] ?? const []);
                  final bytes = await svc.generatePdfBytes(
                    userName: profile?.displayName ?? 'Usuario HAMVIT',
                    periodLabel: '${HamvitDateUtils.formatDateBr(start)} a ${HamvitDateUtils.formatDateBr(end)}',
                    reportType: 'weekly',
                    summary: summary,
                    insights: insights,
                  );
                  if (!mounted) return;
                  setState(() {
                    _pdfBytes = bytes;
                    _reportId = result?['report']?['id']?.toString();
                    _message = 'PDF gerado com sucesso.';
                  });
                },
              ),
              const SizedBox(height: 10),
              HamvitPdfViewer(bytes: _pdfBytes == null ? null : Uint8List.fromList(_pdfBytes!)),
              const SizedBox(height: 10),
              PremiumFeatureGate(
                feature: HamvitFeature.reportsSharing,
                isPremium: widget.isPremium,
                fallback: const SizedBox.shrink(),
                child: HamvitShareSheet(
                  onShare: _pdfBytes == null
                      ? null
                      : () async {
                          await svc.sharePdfBytes(bytes: _pdfBytes!, filename: 'hamvit_relatorio.pdf');
                          if (_reportId != null) {
                            await svc.registerShare(reportId: _reportId!, channel: 'share_sheet');
                          }
                        },
                ),
              ),
            ],
          ),
        ),
        if (_message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_message),
        ],
      ],
    );
  }
}
