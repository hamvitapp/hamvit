import 'package:flutter/material.dart';

enum ActivityEnvironment { indoor, outdoor }
enum ActivityTrackingMode { gps, manual, hybrid }

class ActivityTypeOption {
  final String id;
  final String label;
  final ActivityEnvironment environment;
  final ActivityTrackingMode trackingMode;
  final IconData icon;

  const ActivityTypeOption({
    required this.id,
    required this.label,
    required this.environment,
    required this.trackingMode,
    required this.icon,
  });
}

class HamvitActivityModeSelector extends StatelessWidget {
  final List<ActivityTypeOption> options;
  final ValueChanged<ActivityTypeOption> onSelected;

  const HamvitActivityModeSelector({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Selecione sua atividade',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...options.map((item) => ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    subtitle: Text(item.environment == ActivityEnvironment.outdoor
                        ? 'Outdoor (GPS)'
                        : 'Indoor (estimativa)'),
                    onTap: () => onSelected(item),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

