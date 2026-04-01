import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/insights_provider.dart';
import 'modern_card.dart';
import 'package:shimmer/shimmer.dart';

class AIInsightsCard extends StatelessWidget {
  const AIInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightsProvider = context.watch<InsightsProvider>();
    final insights = insightsProvider.insights;
    final isLoading = insightsProvider.isLoading;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.psychology_rounded, 
                  color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                'AI Coding Insights',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoading && insights.isEmpty)
            _buildLoadingShimmer(theme)
          else if (insights.isEmpty)
             const Text("Connect your profiles and refresh to get personalized AI insights! 🚀")
          else
            ...insights.map((insight) => _buildInsightRow(theme, insight)),
          
          if (insightsProvider.error != null && insights.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Could not load fresh insights. Try again later.',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(ThemeData theme, String insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      highlightColor: theme.colorScheme.surfaceVariant.withOpacity(0.1),
      child: Column(
        children: List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
            ],
          ),
        )),
      ),
    );
  }
}
