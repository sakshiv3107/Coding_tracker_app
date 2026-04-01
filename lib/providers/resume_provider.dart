import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import '../services/ai_service.dart';
import '../services/resume_analysis_service.dart';

class ResumeProvider extends ChangeNotifier {
  String? _resumeUrl;
  String? _resumePath;
  bool _isPdf = false;
  
  bool _isAnalyzing = false;
  String? _resumeSummary;
  String? _codingSummary;
  String? _atsScore;
  String? _recommendations;
  String? _analysisError;
  String? _generatedPdfPath;
  String? _originalSavedPath;

  String? get resumeUrl => _resumeUrl;
  String? get resumePath => _resumePath;
  bool get isPdf => _isPdf;
  bool get isAnalyzing => _isAnalyzing;
  String? get resumeSummary => _resumeSummary;
  String? get codingSummary => _codingSummary;
  String? get atsScore => _atsScore;
  String? get recommendations => _recommendations;
  String? get analysisError => _analysisError;
  String? get generatedPdfPath => _generatedPdfPath;
  String? get originalSavedPath => _originalSavedPath;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _resumeUrl = prefs.getString('resume_url');
    _resumePath = prefs.getString('resume_path');
    _isPdf = prefs.getBool('is_pdf') ?? false;
    _resumeSummary = prefs.getString('resume_summary');
    _codingSummary = prefs.getString('coding_summary');
    _atsScore = prefs.getString('ats_score');
    _recommendations = prefs.getString('recommendations');
    _generatedPdfPath = prefs.getString('generated_pdf_path');
    _originalSavedPath = prefs.getString('original_saved_path');
    notifyListeners();
  }

  Future<void> setResumeUrl(String url) async {
    _resumeUrl = url;
    _resumePath = null;
    _isPdf = false;
    _resumeSummary = null;
    _codingSummary = null;
    _atsScore = null;
    _recommendations = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_url', url);
    await prefs.remove('resume_path');
    await prefs.setBool('is_pdf', false);
    await prefs.remove('resume_summary');
    await prefs.remove('coding_summary');
    await prefs.remove('ats_score');
    await prefs.remove('recommendations');
    notifyListeners();
  }

  Future<void> setResumeFile(String path) async {
    _resumePath = path;
    _resumeUrl = null;
    _isPdf = true;
    _resumeSummary = null;
    _codingSummary = null;
    _atsScore = null;
    _recommendations = null;
    _generatedPdfPath = null;
    _originalSavedPath = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_path', path);
    await prefs.remove('resume_url');
    await prefs.setBool('is_pdf', true);
    await prefs.remove('resume_summary');
    await prefs.remove('coding_summary');
    await prefs.remove('ats_score');
    await prefs.remove('recommendations');
    await prefs.remove('generated_pdf_path');
    await prefs.remove('original_saved_path');
    
    // Save original file securely
    try {
      _originalSavedPath = await ResumeAnalysisService.saveOriginalResume(File(path));
      await prefs.setString('original_saved_path', _originalSavedPath!);
    } catch (e) {
      debugPrint("Error saving original resume: $e");
    }

    notifyListeners();
  }

  Future<void> analyzeResume(String codingProfileData, {required String candidateName, Map<String, dynamic>? stats}) async {
    if (_resumePath == null && _resumeUrl == null) return;
    
    _isAnalyzing = true;
    _analysisError = null;
    _resumeSummary = null;
    _codingSummary = null;
    _generatedPdfPath = null;
    notifyListeners();

    try {
      String resumeText = '';
      if (_isPdf && _resumePath != null) {
        debugPrint('[ResumeProvider] Extracting text from PDF: $_resumePath');
        try {
          resumeText = await ReadPdfText.getPDFtext(_resumePath!);
          resumeText = resumeText.trim();
          debugPrint('[ResumeProvider] Extracted Text: "$resumeText"');
        } catch (extractError) {
          debugPrint('[ResumeProvider] PDF extraction error: $extractError');
          throw Exception('PDF text extraction failed: $extractError');
        }

        if (resumeText.isEmpty) {
          throw Exception(
            'Could not extract text from this PDF. It may be image-based or blank. '
            'Please try a different file.',
          );
        }
      } else if (_resumeUrl != null) {
        resumeText = 'Candidate Portfolio/Resume Link: $_resumeUrl';
      }

      if (resumeText.trim().isEmpty) {
        throw Exception('No resume content available to analyze.');
      }

      // 1. Get AI Analysis
      debugPrint('[ResumeProvider] Sending to AIService...');
      final result = await AIService.analyzeResume(
        resumeText: resumeText,
        codingProfileData: codingProfileData,
      );

      debugPrint('[ResumeProvider] API Response successful: $result');

      _resumeSummary = result['resume_summary'];
      _codingSummary = result['coding_summary'];
      _atsScore = result['ats_score'];
      _recommendations = result['recommendations'];
      
      // 2. Generate Summary PDF
      _generatedPdfPath = await ResumeAnalysisService.generateSummaryPdf(
        name: candidateName,
        resumeSummary: _resumeSummary!,
        codingSummary: _codingSummary!,
        atsScore: _atsScore,
        recommendations: _recommendations,
        extraDetails: stats,
      );

      // 3. Persist everything
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('resume_summary', _resumeSummary!);
      await prefs.setString('coding_summary', _codingSummary!);
      await prefs.setString('ats_score', _atsScore!);
      await prefs.setString('recommendations', _recommendations ?? '');
      await prefs.setString('generated_pdf_path', _generatedPdfPath!);
      
    } catch (e, stackTrace) {
      debugPrint('[ResumeProvider] analyzeResume error: $e');
      debugPrint('[ResumeProvider] Stack trace: $stackTrace');
      // Always produce a clean human-readable error message
      final rawMessage = e.toString();
      _analysisError = rawMessage
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', 'Format error: ')
          .replaceFirst('SocketException: ', 'Network error: ')
          .replaceFirst('TimeoutException: ', 'Request timed out. ');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> clearResume() async {
    _resumeUrl = null;
    _resumePath = null;
    _isPdf = false;
    _resumeSummary = null;
    _codingSummary = null;
    _atsScore = null;
    _recommendations = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resume_url');
    await prefs.remove('resume_path');
    await prefs.remove('is_pdf');
    await prefs.remove('resume_summary');
    await prefs.remove('coding_summary');
    await prefs.remove('ats_score');
    await prefs.remove('recommendations');
    notifyListeners();
  }
}
