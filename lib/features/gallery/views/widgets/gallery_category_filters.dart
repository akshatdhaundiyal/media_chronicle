import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_chronicle/core/constants/app_constants.dart';
import 'package:media_chronicle/core/utils/media_helper.dart';
import 'package:media_chronicle/state/app_state.dart';

class GalleryCategoryFilters extends ConsumerWidget {
  const GalleryCategoryFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final categories = ['All', 'Nature', 'Urban', 'People', 'Events', 'Objects'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isActive = appState.activeGroupFilter == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => ref.read(appStateProvider.notifier).updateGroupFilter(cat),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppConstants.primary.withValues(alpha: 0.2) : AppConstants.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppConstants.primary : AppConstants.cardStroke,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      MediaHelper.getGroupIcon(cat),
                      size: 14,
                      color: isActive ? AppConstants.primary : AppConstants.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? AppConstants.textPrimary : AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
