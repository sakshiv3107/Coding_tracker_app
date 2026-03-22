import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import '../services/ai_service.dart';

class ResumeProvider extends ChangeNotifier {
  String? _resumeUrl;
  String? _resumePath;
  bool _isPdf = false;
  
  // ── AI Analysis State ──────────────────────────────────────────────────
  bool _isAnalyzing = false;
  String? _resumeSummary;
  String? _codingSummary;
  String? _analysisError;

  String? get resumeUrl => _resumeUrl;
  String? get resumePath => _resumePath;
  bool get isPdf => _isPdf;
  bool get isAnalyzing => _isAnalyzing;
  String? get resumeSummary => _resumeSummary;
  String? get codingSummary => _codingSummary;
  String? get analysisError => _analysisError;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _resumeUrl = prefs.getString('resume_url');
    _resumePath = prefs.getString('resume_path');
    _isPdf = prefs.getBool('is_pdf') ?? false;
    _resumeSummary = prefs.getString('resume_summary');
    _codingSummary = prefs.getString('coding_summary');
    notifyListeners();
  }

  Future<void> setResumeUrl(String url) async {
    _resumeUrl = url;
    _resumePath = null;
    _isPdf = false;
    _resumeSummary = null;
    _codingSummary = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_url', url);
    await prefs.remove('resume_path');
    await prefs.setBool('is_pdf', false);
    await prefs.remove('resume_summary');
    await prefs.remove('coding_summary');
    notifyListeners();
  }

  Future<void> setResumeFile(String path) async {
    _resumePath = path;
    _resumeUrl = null;
    _isPdf = true;
    _resumeSummary = null;
    _codingSummary = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_path', path);
    await prefs.remove('resume_url');
    await prefs.setBool('is_pdf', true);
    await prefs.remove('resume_summary');
    await prefs.remove('coding_summary');
    notifyListeners();
    
    // Automatically trigger analysis if it's a file
    // (Actual call will be made from UI or explicitly based on user choice)
  }

  Future<void> analyzeResume(String codingProfileData) async {
    if (_resumePath == null && _resumeUrl == null) return;
    
    _isAnalyzing = true;
    _analysisError = null;
    notifyListeners();

    try {
      String resumeText = "";
      if (_isPdf && _resumePath != null) {
        resumeText = await ReadPdfText.getPDFtext(_resumePath!);
      } else if (_resumeUrl != null) {
        resumeText = "Candidate Portfolio Link: $_resumeUrl";
      }

      // If no API key, use dummy (for testing)
      final result = await AIService.analyzeResume(
        resumeText: resumeText,
        codingProfileData: codingProfileData,
      ).catchError((_) => AIService.getDummyAnalysis());

      _resumeSummary = result['resume_summary'];
      _codingSummary = result['coding_summary'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('resume_summary', _resumeSummary!);
      await prefs.setString('coding_summary', _codingSummary!);
      
    } catch (e) {
      _analysisError = e.toString();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resume_url');
    await prefs.remove('resume_path');
    await prefs.remove('is_pdf');
    await prefs.remove('resume_summary');
    await prefs.remove('coding_summary');
    notifyListeners();
  }
}
