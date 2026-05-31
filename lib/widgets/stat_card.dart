import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isAlert;
  final VoidCallback? onTap;   // ← NEW

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isAlert = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isAlert
                ? AppColors.danger.withOpacity(0.85)
                : AppColors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isAlert
                  ? AppColors.danger
                  : AppColors.white.withOpacity(0.35),
              width: isAlert ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.white),
                  const Spacer(),
                  if (onTap != null)
                    Icon(Icons.chevron_right_rounded,
                        size: 13, color: AppColors.white.withOpacity(0.6)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.white, height: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600,
                  color: AppColors.white.withOpacity(0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
