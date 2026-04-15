import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/glassmorphic_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UploadCard extends StatelessWidget {
  final String? filePath;
  final String? url;
  final bool isPdf;
  final VoidCallback onPickPdf;
  final VoidCallback onAddLink;
  final VoidCallback onRemove;

  const UploadCard({
    super.key,
    this.filePath,
    this.url,
    this.isPdf = true,
    required this.onPickPdf,
    required this.onAddLink,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = filePath != null || url != null;

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!hasFile) ...[
            SizedBox(
              height: 110,
              child: GlassmorphicContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                opacity: 0.03,
                child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .moveY(begin: -2, end: 2, duration: 2.seconds),
                    const SizedBox(height: 12),
                    Text(
                      "Upload your resume to get instant insights",
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: "Upload PDF",
                    icon: Icons.picture_as_pdf_rounded,
                    isPrimary: true,
                    onPressed: onPickPdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: "Add Link",
                    icon: Icons.link_rounded,
                    isPrimary: false,
                    onPressed: onAddLink,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.link_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPdf ? (filePath?.split(Platform.pathSeparator).last ?? "Resume.pdf") : "Portfolio Link",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isPdf ? "Successfully uploaded" : url ?? "",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error.withOpacity(0.5), size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ).animate().fadeIn(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: isPrimary ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7)),
        label: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}


