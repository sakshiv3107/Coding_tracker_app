// lib/services/insight_engine.dart

import '../models/insight_model.dart';
import '../services/ai_service.dart';

class InsightEngine {
  /// Analyzes raw user stats using rule-based logic primarily,
  /// and enhances them with AI if needed.
  static Future<List<InsightModel>> analyzeUserData(
    Map<String, dynamic> data,
  ) async {
    List<InsightModel> insights = [];

    final topicPerformance = (data['topicPerformance'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as Map<String, dynamic>),
    );
    
    

    // ─── 1. Rule: Recent Performance Weaknesses ────────────────────────────────
    topicPerformance.forEach((topic, stats) {
      final attempts = (stats['attempts'] as num).toInt();
      final correct = (stats['correct'] as num).toInt();
      final accuracy = attempts > 0 ? correct / attempts : 1.0;

      if (attempts >= 3 && accuracy < 0.5) {
        insights.add(
          InsightModel(
            id: 'recent_weak_$topic',
            title: 'Low accuracy in $topic recently',
            reason: 'Your accuracy in recent $topic problems is only ${(accuracy * 100).toInt()}%. This indicates a need for concept revision.',
            impact: '$topic is frequently tested and requires high accuracy for competitive coding.',
            confidence: 'High',
            topic: topic,
            type: InsightType.weakness,
            emoji: '⚠️',
          ),
        );
      }
    });

    // ─── 2. Rule: Topic Focus Tracking ─────────────────────────────────────────
    final totalRecentAttempts = topicPerformance.values.fold<int>(0, (sum, stats) => sum + (stats['attempts'] as num).toInt());
    topicPerformance.forEach((topic, stats) {
        final attempts = (stats['attempts'] as num).toInt();
        if (attempts / totalRecentAttempts > 0.6 && attempts >= 5) {
             insights.add(
              InsightModel(
                id: 'focus_$topic',
                title: 'Heavily focusing on $topic',
                reason: 'You have dedicated ${(attempts/totalRecentAttempts*100).toInt()}% of your last 20 problems to $topic.',
                impact: 'While mastery is good, don\'t forget to maintain a balanced practice routine.',
                confidence: 'High',
                topic: topic,
                type: InsightType.strength,
                emoji: '🔍',
              ),
            );
        }
    });

    // ─── 3. Rule: Mastery Insight ──────────────────────────────────────────────
    topicPerformance.forEach((topic, stats) {
        final attempts = (stats['attempts'] as num).toInt();
        final correct = (stats['correct'] as num).toInt();
        if (attempts >= 5 && correct / attempts > 0.8) {
             insights.add(
              InsightModel(
                id: 'mastery_$topic',
                title: 'Excellent performance in $topic',
                reason: 'You correctly solved $correct out of $attempts recent $topic problems!',
                impact: 'Strong mastery of $topic allows you to tackle more complex combined algorithm problems.',
                confidence: 'High',
                topic: topic,
                type: InsightType.strength,
                emoji: '⭐',
              ),
            );
        }
    });

    // ─── AI Enhancement ────────────────────────────────────────────────────────
    // If we have fewer than 3 insights, or if we want better phrasing, call AI.
    if (insights.length < 3) {
      try {
        final aiInsights = await AIService.generateStructuredInsights(
          userData: data,
        );
        for (final raw in aiInsights) {
          final model = InsightModel.fromJson(raw as Map<String, dynamic>);
          // Avoid duplicates by title
          if (!insights.any((i) => i.title == model.title)) {
            insights.add(model);
          }
        }
      } catch (e) {
        // Fallback silently if AI fails
      }
    }

    // ─── Prioritization & Limiting ─────────────────────────────────────────────
    // Sort by type (weakness > slowness > errorRate > strength)
    // and then by confidence.
    insights.sort((a, b) {
      final typeOrder = {
        InsightType.weakness: 0,
        InsightType.errorRate: 1,
        InsightType.slowness: 2,
        InsightType.strength: 3,
      };
      return (typeOrder[a.type] ?? 9).compareTo(typeOrder[b.type] ?? 9);
    });

    return insights.take(5).toList();
  }
}
