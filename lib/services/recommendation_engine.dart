// lib/services/recommendation_engine.dart

import '../models/insight_model.dart';
import '../services/ai_service.dart';

class RecommendationEngine {
  static Future<List<RecommendationModel>> generateRecommendations({
    required Map<String, dynamic> userData,
    required List<InsightModel> insights,
  }) async {
    final List<RecommendationModel> recommendations = [];
    
    final topicPerformance = userData['topicPerformance'] as Map<String, dynamic>? ?? {};
    final recentSubs = userData['recentSubmissions'] as List<dynamic>? ?? [];

    // Case 1: Weak topic (Focus)
    String? weakTopic;
    double lowestAcc = 1.0;
    topicPerformance.forEach((topic, stats) {
        final attempts = (stats['attempts'] as num).toInt();
        final correct = (stats['correct'] as num).toInt();
        final acc = attempts > 0 ? correct / attempts : 1.0;
        if (attempts >= 2 && acc < 0.5 && acc < lowestAcc) {
            lowestAcc = acc;
            weakTopic = topic;
        }
    });

    if (weakTopic != null) {
        recommendations.add(RecommendationModel(
            title: 'Focus on $weakTopic fundamentals',
            description: 'Your recent accuracy in $weakTopic is low (${(lowestAcc * 100).toInt()}%). Strengthening the basics will help.',
            icon: '🎯',
            type: 'focus',
            priority: RecommendationPriority.high,
        ));
    }

    // Case 2: Improving topic (Improve)
    String? improvingTopic;
    topicPerformance.forEach((topic, stats) {
        final attempts = (stats['attempts'] as num).toInt();
        final correct = (stats['correct'] as num).toInt();
        final acc = attempts > 0 ? correct / attempts : 0.0;
        if (attempts >= 3 && acc >= 0.5 && acc < 0.8) {
            improvingTopic = topic;
        }
    });

    if (improvingTopic != null && improvingTopic != weakTopic) {
        recommendations.add(RecommendationModel(
            title: 'Level up in $improvingTopic',
            description: 'You are improving in $improvingTopic! Try moving to medium-level problems to push your limits.',
            icon: '📈',
            type: 'improve',
            priority: RecommendationPriority.medium,
        ));
    }

    // Case 3: Strong topic (Challenge)
    String? strongTopic;
    topicPerformance.forEach((topic, stats) {
        final attempts = (stats['attempts'] as num).toInt();
        final correct = (stats['correct'] as num).toInt();
        final acc = attempts > 0 ? correct / attempts : 0.0;
        if (attempts >= 3 && acc >= 0.8) {
            strongTopic = topic;
        }
    });

    if (strongTopic != null && recommendations.length < 2) {
        recommendations.add(RecommendationModel(
            title: 'Challenge yourself in $strongTopic',
            description: 'You have mastered basic $strongTopic. Try some Hard problems to sharpen your skills.',
            icon: '🔥',
            type: 'challenge',
            priority: RecommendationPriority.medium,
        ));
    }

    // Case 4: Imbalance (Balance)
    if (recentSubs.isNotEmpty) {
        final totalRecent = recentSubs.length;
        String? dominantTopic;
        topicPerformance.forEach((topic, stats) {
            final attempts = (stats['attempts'] as num).toInt();
            if (attempts / totalRecent > 0.6) {
                dominantTopic = topic;
            }
        });

        if (dominantTopic != null && recommendations.length < 3) {
             recommendations.add(RecommendationModel(
                title: 'Diversify your practice',
                description: 'You\'ve been focusing heavily on $dominantTopic. Try exploring Graphs or Trees for better balance.',
                icon: '⚖️',
                type: 'balance',
                priority: RecommendationPriority.medium,
            ));
        }
    }

    // AI Fallback if we have fewer recommendations
    if (recommendations.length < 2) {
        try {
            final aiRecs = await AIService.generateRecommendations(
                insights: insights.map((e) => {'topic': e.topic, 'type': e.type.toString()}).toList(),
                topicStats: topicPerformance,
                totalSolved: userData['totalSolved'] ?? 0,
                difficultyBreakdown: {
                    'easy': userData['platforms']?['leetcode']?['easy'] ?? 0,
                    'medium': userData['platforms']?['leetcode']?['medium'] ?? 0,
                    'hard': userData['platforms']?['leetcode']?['hard'] ?? 0,
                },
                recentSubmissions: userData['recentSubmissions'] ?? [],
            );
            
            for (final raw in aiRecs) {
                if (recommendations.length >= 3) break;
                recommendations.add(RecommendationModel.fromJson(raw as Map<String, dynamic>));
            }
        } catch (e) {
            // Silently fail AI recommendations
        }
    }

    return recommendations.take(3).toList();
  }
}
