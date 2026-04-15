// lib/providers/resume_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import '../services/ai_service.dart';
import '../services/resume_analysis_service.dart';

class ResumeProvider extends ChangeNotifier {
  // ─── File / URL state ──────────────────────────────────────────────────────
  String? _resumeUrl;
  String? _resumePath;
  bool _isPdf = false;

  // ─── Analysis state ────────────────────────────────────────────────────────
  bool _isAnalyzing = false;
  String? _analysisError;

  // Flat string fields kept for backward-compat with PDF generation & UI
  String? _resumeSummary;
  String? _recommendations;
  String? _atsScore;

  // New typed result — use this in any new UI widgets
  ResumeAnalysisResult? _analysisResult;

  // Legacy field — kept so existing PDF generator doesn't break.
  // Populated with a placeholder when codingProfileData is no longer relevant.
  String? _codingSummary;

  // PDF paths
  String? _generatedPdfPath;
  String? _originalSavedPath;

  // ─── Getters ───────────────────────────────────────────────────────────────
  String? get resumeUrl          => _resumeUrl;
  String? get resumePath         => _resumePath;
  bool   get isPdf               => _isPdf;
  bool   get isAnalyzing         => _isAnalyzing;
  String? get resumeSummary      => _resumeSummary;
  String? get codingSummary      => _codingSummary;
  String? get atsScore           => _atsScore;
  String? get recommendations    => _recommendations;
  String? get analysisError      => _analysisError;
  String? get generatedPdfPath   => _generatedPdfPath;
  String? get originalSavedPath  => _originalSavedPath;

  /// Typed result — null until analysis completes successfully.
  ResumeAnalysisResult? get analysisResult => _analysisResult;

  // ─── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _resumeUrl          = prefs.getString('resume_url');
    _resumePath         = prefs.getString('resume_path');
    _isPdf              = prefs.getBool('is_pdf') ?? false;
    _resumeSummary      = prefs.getString('resume_summary');
    _codingSummary      = prefs.getString('coding_summary');
    _atsScore           = prefs.getString('ats_score');
    _recommendations    = prefs.getString('recommendations');
    _generatedPdfPath   = prefs.getString('generated_pdf_path');
    _originalSavedPath  = prefs.getString('original_saved_path');
    notifyListeners();
  }

  // ─── Set resume via URL ────────────────────────────────────────────────────
  Future<void> setResumeUrl(String url) async {
    _resumeUrl       = url;
    _resumePath      = null;
    _isPdf           = false;
    _analysisResult  = null;
    _clearAnalysisFields();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_url', url);
    await prefs.remove('resume_path');
    await prefs.setBool('is_pdf', false);
    await _clearPersistedAnalysis(prefs);
    notifyListeners();
  }

  // ─── Set resume via local file ─────────────────────────────────────────────
  Future<void> setResumeFile(String path) async {
    _resumePath         = path;
    _resumeUrl          = null;
    _isPdf              = true;
    _analysisResult     = null;
    _generatedPdfPath   = null;
    _originalSavedPath  = null;
    _clearAnalysisFields();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_path', path);
    await prefs.remove('resume_url');
    await prefs.setBool('is_pdf', true);
    await _clearPersistedAnalysis(prefs);
    await prefs.remove('generated_pdf_path');
    await prefs.remove('original_saved_path');

    try {
      _originalSavedPath =
          await ResumeAnalysisService.saveOriginalResume(File(path));
      await prefs.setString('original_saved_path', _originalSavedPath!);
    } catch (e) {
      debugPrint('[ResumeProvider] Error saving original resume: $e');
    }

    notifyListeners();
  }

  // ─── ANALYZE RESUME ────────────────────────────────────────────────────────
  /// [jobDescription] is optional — pass the target JD text for keyword
  ///   matching, or leave null for a general ATS evaluation.
  ///
  /// [codingProfileData] is kept as an optional param so existing call-sites
  ///   don't break — it is no longer forwarded to AIService but can still be
  ///   embedded in the generated PDF via [stats].
  Future<void> analyzeResume({
    required String candidateName,
    String? jobDescription,
    @Deprecated('Replaced by jobDescription. Pass coding stats via stats.')
    String? codingProfileData,
    Map<String, dynamic>? stats,
  }) async {
    if (_resumePath == null && _resumeUrl == null) return;

    _isAnalyzing    = true;
    _analysisError  = null;
    _analysisResult = null;
    _generatedPdfPath = null;
    _clearAnalysisFields();
    notifyListeners();

    try {
      // ── 1. Extract resume text ─────────────────────────────────────────────
      String resumeText = '';

      if (_isPdf && _resumePath != null) {
        debugPrint('[ResumeProvider] Extracting PDF text: $_resumePath');
        try {
          resumeText = (await ReadPdfText.getPDFtext(_resumePath!)).trim();
          debugPrint('[ResumeProvider] Extracted ${resumeText.length} chars');
        } catch (e) {
          throw Exception('PDF text extraction failed: $e');
        }

        if (resumeText.isEmpty) {
          throw Exception(
            'Could not extract text from this PDF. '
            'It may be image-based or password-protected. '
            'Please try a different file.',
          );
        }
      } else if (_resumeUrl != null) {
        resumeText = 'Candidate Portfolio / Resume URL: $_resumeUrl';
      }

      if (resumeText.trim().isEmpty) {
        throw Exception('No resume content available to analyze.');
      }

      // ── 2. Call AI service ─────────────────────────────────────────────────
      debugPrint('[ResumeProvider] Sending to AIService.analyzeResume...');

      final result = await AIService.analyzeResume(
        resumeText: resumeText,
        jobDescription: jobDescription,   // optional JD for keyword matching
      );

      debugPrint(
        '[ResumeProvider] Analysis complete — ATS score: ${result.atsScore}',
      );

      _analysisResult = result;

      // ── 3. Flatten typed result into legacy string fields ─────────────────
      //    These keep existing UI widgets & PDF generator working unchanged.
      _atsScore       = result.atsScore.toString();
      _resumeSummary  = result.resumeSummary.map((p) => '• $p').join('\n');

      _recommendations = result.recommendations
          .map((r) {
            final tag = '[${r.priority.toUpperCase()}] ${r.category}';
            return '$tag\n${r.issue}\n-> ${r.fix}';
          })
          .join('\n\n');

      // codingSummary: not returned by the new rubric-based analysis.
      // Populate with the per-criterion score notes so the PDF still has
      // meaningful content in that section.
      final breakdownLines = result.scoreBreakdown.entries.map((e) {
        final label = _formatCriterionLabel(e.key);
        return '• $label: ${e.value.score} pts — ${e.value.note}';
      }).join('\n');
      _codingSummary = 'ATS Score Breakdown\n$breakdownLines';

      // ── 4. Generate summary PDF ────────────────────────────────────────────
      _generatedPdfPath = await ResumeAnalysisService.generateSummaryPdf(
        name: candidateName,
        resumeSummary: _resumeSummary!,
        codingSummary: _codingSummary!,
        atsScore: _atsScore,
        recommendations: _recommendations,
        extraDetails: stats,
      );

      // ── 5. Persist to SharedPreferences ───────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('resume_summary',    _resumeSummary!);
      await prefs.setString('coding_summary',    _codingSummary!);
      await prefs.setString('ats_score',         _atsScore!);
      await prefs.setString('recommendations',   _recommendations ?? '');
      await prefs.setString('generated_pdf_path', _generatedPdfPath!);

    } catch (e, st) {
      debugPrint('[ResumeProvider] analyzeResume error: $e');
      debugPrint('[ResumeProvider] $st');
      _analysisError = e
          .toString()
          .replaceFirst('Exception: ',        '')
          .replaceFirst('FormatException: ',  'Format error: ')
          .replaceFirst('SocketException: ',  'Network error: ')
          .replaceFirst('TimeoutException: ', 'Request timed out. ');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // ─── Clear ─────────────────────────────────────────────────────────────────
  Future<void> clearResume() async {
    _resumeUrl      = null;
    _resumePath     = null;
    _isPdf          = false;
    _analysisResult = null;
    _clearAnalysisFields();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resume_url');
    await prefs.remove('resume_path');
    await prefs.remove('is_pdf');
    await _clearPersistedAnalysis(prefs);
    notifyListeners();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  void _clearAnalysisFields() {
    _resumeSummary   = null;
    _codingSummary   = null;
    _atsScore        = null;
    _recommendations = null;
  }

  Future<void> _clearPersistedAnalysis(SharedPreferences prefs) async {
    await prefs.remove('resume_summary');
    await prefs.remove('coding_summary');
    await prefs.remove('ats_score');
    await prefs.remove('recommendations');
  }

  static String _formatCriterionLabel(String key) {
    const labels = {
      'format_template':            'Format & Template',
      'action_verbs':               'Action Verbs',
      'quantifiable_achievements':  'Quantifiable Achievements',
      'keyword_relevance':          'Keyword Relevance',
      'contact_links':              'Contact & Links',
      'completeness':               'Completeness',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }
}


