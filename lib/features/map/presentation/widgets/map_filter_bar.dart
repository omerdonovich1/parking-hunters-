import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/parking_spot_model.dart';

/// Which status filters are currently active (null = all shown).
final activeFiltersProvider =
    StateProvider<Set<SpotStatus>>((ref) => SpotStatus.values.toSet());

class MapFilterBar extends ConsumerWidget {
  const MapFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeFiltersProvider);

    final filters = [
      _Filter(SpotStatus.available, '🟢', 'Available', const Color(0xFF4CAF50)),
      _Filter(SpotStatus.soonAvailable, '🟡', 'Soon', const Color(0xFFFFA726)),
      _Filter(
          SpotStatus.lowConfidence, '🔴', 'Low conf.', const Color(0xFFEF5350)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: filters.map((f) {
          final selected = active.contains(f.status);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(f.label),
                ],
              ),
              selected: selected,
              onSelected: (val) {
                final current = Set<SpotStatus>.from(active);
                if (val) {
                  current.add(f.status);
                } else {
                  // Always keep at least one filter active
                  if (current.length > 1) current.remove(f.status);
                }
                ref.read(activeFiltersProvider.notifier).state = current;
              },
              selectedColor: f.color.withValues(alpha: 0.2),
              checkmarkColor: f.color,
              labelStyle: TextStyle(
                color: selected ? f.color : Colors.grey.shade700,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: selected ? f.color : Colors.grey.shade300,
              ),
              backgroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Filter {
  final SpotStatus status;
  final String emoji;
  final String label;
  final Color color;
  const _Filter(this.status, this.emoji, this.label, this.color);
}
