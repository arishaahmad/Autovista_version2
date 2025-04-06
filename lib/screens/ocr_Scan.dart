import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  File? _pickedImage;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _pickedImage = File(pickedFile.path);
      _isLoading = true;
    });

    final inputImage = InputImage.fromFile(_pickedImage!);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    final parsedData = _extractVehicleData(recognizedText.text);

    setState(() => _isLoading = false);

    if (context.mounted) {
      Navigator.pop(context, parsedData);
    }
  }

  Map<String, dynamic> _extractVehicleData(String text) {
    final Map<String, dynamic> data = {
      'brand': _matchRegex(text, r'Brand[:\s]*([\w ]+)'),
      'model': _matchRegex(text, r'Model[:\s]*([\w\d ]+)'),
      'engine_type': _matchRegex(text, r'Engine Type[:\s]*([\w ]+)'),
      'mileage': _matchRegex(text, r'Mileage[:\s]*([\d,]+)'),
      'region': _matchRegex(text, r'Region[:\s]*([\w ]+)'),
      'make_year': _matchRegex(text, r'Make Year[:\s]*(\d{4})'),
    };
    return data;
  }

  String? _matchRegex(String input, String pattern) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(input);
    return match?.group(1)?.trim();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Vehicle Document")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_pickedImage != null)
                    Image.file(_pickedImage!, height: 250),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Photo"),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Choose from Gallery"),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
      ),
    );
  }
}
