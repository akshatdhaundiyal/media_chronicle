import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/media_helper.dart';
import '../../../../state/app_state.dart';

class GalleryCategoryFilters extends StatelessWidget {
  const GalleryCategoryFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
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
              onTap: () => appState.updateGroupFilter(cat),
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
