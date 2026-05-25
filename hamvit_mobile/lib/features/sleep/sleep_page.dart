import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hamvit_date_utils.dart';
import '../../core/supabase_provider.dart';
import '../../shared/widgets/hamvit_module_widgets.dart';
import '../../shared/widgets/hamvit_time_input.dart';
import '../home/providers/home_dashboard_provider.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';

class SleepPage extends ConsumerStatefulWidget {
  const SleepPage({super.key});

  @override
  ConsumerState<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends ConsumerState<SleepPage> {
  bool _loading = true;
  String? _lastRecord;
  double? _lastHours;
  int? _lastQuality;
  List<String> _weeklyHistory = const [];

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  Future<void> _loadSleepData() async {
    final client = ref.read(supabaseClientProvider);
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      return;
    }

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    try {
      final rows = await client
          .from('sleep_logs')
          .select('sleep_date, duration_minutes, total_sleep_minutes, quality, sleep_quality, slept_at, woke_at, notes')
          .eq('user_id', uid)
          .gte('sleep_date', HamvitDateUtils.toIsoDate(weekStart))
          .order('sleep_date', ascending: false);

      if (!mounted) return;

      if (rows.isEmpty) {
        setState(() {
          _loading = false;
          _lastRecord = null;
          _lastHours = null;
          _lastQuality = null;
          _weeklyHistory = const [];
        });
        return;
      }

      final latest = rows.first;
      final latestMinutes = _minutesFromRow(latest);
      final latestQuality = _qualityFromRow(latest);

      final history = rows.map((row) {
        final date = DateTime.tryParse((row['sleep_date'] ?? '').toString());
        final weekday = _weekdayShort(date);
        final mins = _minutesFromRow(row);
        final quality = _qualityFromRow(row);
        return '$weekday: ${_formatMinutes(mins)} - Qualidade ${_qualityLabel(quality)}';
      }).toList();

      setState(() {
        _loading = false;
        _lastHours = latestMinutes == null ? null : latestMinutes / 60.0;
        _lastQuality = latestQuality;
        _lastRecord = _buildLastRecord(latest, latestQuality);
        _weeklyHistory = history;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  int? _minutesFromRow(Map<String, dynamic> row) {
    final v1 = row['duration_minutes'];
    if (v1 is num) return v1.toInt();
    final v2 = row['total_sleep_minutes'];
    if (v2 is num) return v2.toInt();
    return null;
  }

  int _qualityFromRow(Map<String, dynamic> row) {
    final v1 = row['quality'];
    if (v1 is num) return v1.toInt().clamp(1, 4).toInt();
    if (v1 is String) {
      final parsed = int.tryParse(v1.trim());
      if (parsed != null) return parsed.clamp(1, 4).toInt();
    }
    final v2 = row['sleep_quality'];
    if (v2 is num) return v2.toInt().clamp(1, 4).toInt();
    if (v2 is String) {
      final parsed = int.tryParse(v2.trim());
      if (parsed != null) return parsed.clamp(1, 4).toInt();
    }
    return 3;
  }

  String _qualityLabel(int q) {
    switch (q) {
      case 1:
        return 'baixa';
      case 2:
        return 'regular';
      case 3:
        return 'boa';
      case 4:
        return 'otima';
      default:
        return 'boa';
    }
  }

  String _weekdayShort(DateTime? date) {
    if (date == null) return '--';
    const names = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    return names[(date.weekday - 1).clamp(0, 6)];
  }

  String _formatMinutes(int? minutes) {
    if (minutes == null || minutes <= 0) return '0h00';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  String _buildLastRecord(Map<String, dynamic> row, int quality) {
    final slept = (row['slept_at'] ?? '').toString();
    final woke = (row['woke_at'] ?? '').toString();
    final sleptAt = DateTime.tryParse(slept);
    final wokeAt = DateTime.tryParse(woke);
    final start = sleptAt == null
        ? '--:--'
        : '${sleptAt.hour.toString().padLeft(2, '0')}:${sleptAt.minute.toString().padLeft(2, '0')}';
    final end = wokeAt == null
        ? '--:--'
        : '${wokeAt.hour.toString().padLeft(2, '0')}:${wokeAt.minute.toString().padLeft(2, '0')}';
    return '$start -> $end - Qualidade ${_qualityLabel(quality)}';
  }

  Future<void> _editSleepGoal(double currentGoal) async {
    final ctrl = TextEditingController(text: currentGoal.toStringAsFixed(1));
    final notifier = ref.read(onboardingProfileProvider.notifier);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar meta de sono'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Horas por noite'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final hours = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (hours == null) return;
              await notifier.saveSleepProfile(hoursTarget: hours);
              if (!mounted) return;
              Navigator.of(this.context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  int? _parseTimeToMinutes(String hhmm) {
    final text = hhmm.trim();
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(text);
    if (match == null) return null;
    final h = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  Future<void> _registerSleep() async {
    final client = ref.read(supabaseClientProvider);
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessao invalida. Faca login novamente.')),
      );
      return;
    }

    final sleepCtrl = TextEditingController();
    final wakeCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: HamvitDateUtils.formatDateBr(DateTime.now()));
    final noteCtrl = TextEditingController();
    var quality = 3;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar sono'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Data do sono (DD/MM/AAAA)'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (picked != null) {
                          dateCtrl.text = HamvitDateUtils.formatDateBr(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sleepCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        HamvitTimeMaskFormatter(),
                      ],
                      decoration: const InputDecoration(labelText: 'Horario que dormiu (HH:MM)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: wakeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        HamvitTimeMaskFormatter(),
                      ],
                      decoration: const InputDecoration(labelText: 'Horario que acordou (HH:MM)'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: quality,
                      decoration: const InputDecoration(labelText: 'Qualidade do sono'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Baixa')),
                        DropdownMenuItem(value: 2, child: Text('Regular')),
                        DropdownMenuItem(value: 3, child: Text('Boa')),
                        DropdownMenuItem(value: 4, child: Text('Otima')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => quality = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Observacao opcional'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final date = HamvitDateUtils.tryParseBrDate(dateCtrl.text);
                    final sleepMin = _parseTimeToMinutes(sleepCtrl.text);
                    final wakeMin = _parseTimeToMinutes(wakeCtrl.text);

                    if (date == null || sleepMin == null || wakeMin == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Preencha data e horarios validos.')),
                      );
                      return;
                    }

                    var duration = wakeMin - sleepMin;
                    if (duration <= 0) duration += 24 * 60;

                    final sleepDateIso = HamvitDateUtils.toIsoDate(date);
                    final sleptAt = DateTime(date.year, date.month, date.day, sleepMin ~/ 60, sleepMin % 60);
                    final wakeBase = DateTime(date.year, date.month, date.day, wakeMin ~/ 60, wakeMin % 60);
                    final wokeAt = duration + sleepMin >= 24 * 60 ? wakeBase.add(const Duration(days: 1)) : wakeBase;

                    final existing = await client
                        .from('sleep_logs')
                        .select('id')
                        .eq('user_id', uid)
                        .eq('sleep_date', sleepDateIso)
                        .limit(1);

                    if (existing.isNotEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Ja existe registro para essa data.')),
                      );
                      return;
                    }

                    await client.from('sleep_logs').insert({
                      'user_id': uid,
                      'sleep_date': sleepDateIso,
                      'slept_at': sleptAt.toIso8601String(),
                      'woke_at': wokeAt.toIso8601String(),
                      'duration_minutes': duration,
                      'quality': quality,
                      'notes': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      'total_sleep_minutes': duration,
                      'sleep_quality': quality,
                    });

                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ref.invalidate(homeDashboardProvider);
                    await _loadSleepData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Sono registrado com sucesso.')),
                    );
                  },
                  child: const Text('Salvar registro'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProfileProvider);
    final goal = state.sleepHours ?? 8.0;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HamvitSectionHeader(
          title: 'Sono',
          subtitle: 'Acompanhe meta de sono, qualidade e historico semanal.',
        ),
        const SizedBox(height: 12),
        HamvitModuleSummaryCard(
          title: 'Meta de sono',
          description: '${goal.toStringAsFixed(1)} horas por noite',
          action: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _editSleepGoal(goal),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar meta de sono'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        HamvitMetricCard(
          label: 'Ultimo registro',
          value: _lastRecord == null ? 'Sem registro' : 'Registrado',
          icon: Icons.bedtime_outlined,
          helper: _lastRecord ?? 'Use o botao abaixo para registrar sua noite.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: HamvitMetricCard(
                label: 'Horas dormidas (ultimo dia)',
                value: _lastHours == null ? 'Sem registro' : _formatMinutes((_lastHours! * 60).round()),
                icon: Icons.timelapse,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: HamvitMetricCard(
                label: 'Qualidade do sono',
                value: _lastQuality == null ? 'Sem registro' : _qualityLabel(_lastQuality!),
                icon: Icons.self_improvement,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _registerSleep,
          icon: const Icon(Icons.addchart_outlined),
          label: const Text('Registrar sono'),
        ),
        const SizedBox(height: 8),
        HamvitHistoryCard(
          title: 'Historico semanal',
          items: _weeklyHistory,
          icon: Icons.calendar_today_outlined,
        ),
      ],
    );
  }
}
