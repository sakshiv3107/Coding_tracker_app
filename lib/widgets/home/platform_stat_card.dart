import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class PlatformStatCard extends StatelessWidget {
  final String platformName;
  final String? username;
  final String primaryStat;
  final String secondaryStat;
  final List<int> dailyActivity;
  final Color platformColor;
  final Widget icon;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onConnect;
  final VoidCallback? onTap;

  const PlatformStatCard({
    super.key,
    required this.platformName,
    this.username,
    required this.primaryStat,
    required this.secondaryStat,
    required this.dailyActivity,
    required this.platformColor,
    required this.icon,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onConnect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmer(context);
    }

    final isNotConnected = username == null || username!.isEmpty || username!.trim().isEmpty;

    return InkWell(
      onTap: isNotConnected ? onConnect : onTap, // If not connected, tap to connect, otherwise tap to view screen
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platformName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (isNotConnected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Connect account →",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7B68EE),
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      primaryStat,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.displayLarge?.color,
                      ),
                    ),
                    Text(
                      secondaryStat,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isNotConnected)
              error != null
                  ? _buildRetryButton()
                  : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: platformColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: icon,
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF9F27).withOpacity(0.15),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Retry",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEF9F27),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.refresh,
              size: 14,
              color: Color(0xFFEF9F27),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.withOpacity(0.1),
      highlightColor: Colors.grey.withOpacity(0.05),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 80, height: 12, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 120, height: 20, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


