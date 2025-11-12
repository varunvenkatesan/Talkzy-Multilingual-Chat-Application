import 'package:flutter/material.dart';
import 'package:talkzy_beta1/services/translation_service.dart';

/// Simple test screen to verify Gemini API is working
class TranslationTestScreen extends StatefulWidget {
  const TranslationTestScreen({super.key});

  @override
  State<TranslationTestScreen> createState() => _TranslationTestScreenState();
}

class _TranslationTestScreenState extends State<TranslationTestScreen> {
  final TranslationService _translationService = TranslationService();
  String _result = 'Tap button to test translation';
  bool _isLoading = false;

  Future<void> _testTranslation() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing...';
    });

    try {
      final translated = await _translationService.translateText(
        'Hello',
        'Hindi',
      );
      
      setState(() {
        _result = 'Success!\nOriginal: Hello\nTranslated: $translated';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Translation API')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _result,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _testTranslation,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Test Translation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}