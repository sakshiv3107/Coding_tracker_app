// lib/widgets/insight/ai_chat_coach.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIChatCoach extends StatefulWidget {
  final List<Map<String, String>> history;
  final Function(String message) onSend;
  final bool isTyping;
  final String? errorMessage;

  const AIChatCoach({
    super.key,
    required this.history,
    required this.onSend,
    required this.isTyping,
    this.errorMessage,
  });

  @override
  State<AIChatCoach> createState() => _AIChatCoachState();
}

class _AIChatCoachState extends State<AIChatCoach> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    "Give me a 2-week study plan",
    "Why do I keep getting TLE?",
    "What should I practice before my next contest?",
  ];

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSend(_controller.text.trim());
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.psychology_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "AI Chat Coach",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                if (widget.isTyping) const _TypingIndicator(),
              ],
            ),
          ),

          // Chat area
          Expanded(
            child: widget.history.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.history.length,
                    itemBuilder: (context, index) {
                      final msg = widget.history[index];
                      return _buildMessage(context, msg);
                    },
                  ),
          ),

          // Error area
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                widget.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 11),
              ),
            ),

          // Suggestions
          if (widget.history.isEmpty) _buildSuggestions(context),

          // Input area
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Ask your coach...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: widget.isTyping ? null : _handleSend,
                  icon: const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 40,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 12),
          Text(
            "Hi! I'm your CodeSphere coach.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          Text(
            "Ask me anything about your practice.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child:
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Text(
              msg['content']!,
              style: TextStyle(
                color: isUser ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ).animate().scale(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            begin: const Offset(0.8, 0.8),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: _suggestions.map(
          (s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                _controller.text = s;
                _handleSend();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ).toList(),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) =>
            Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  delay: (index * 150).ms,
                  duration: 400.ms,
                ),
      ),
    );
  }
}
