import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploadPage extends StatefulWidget {
  const CloudinaryUploadPage({super.key});

  @override
  State<CloudinaryUploadPage> createState() => _CloudinaryUploadPageState();
}

class _CloudinaryUploadPageState extends State<CloudinaryUploadPage> {
  bool isUploading = false;
  String? uploadedUrl;

  // Your Cloudinary details
  final String cloudName = "dzxbqfatf";
  final String uploadPreset = "student_presets";

  Future<void> uploadFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() => isUploading = true);

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/auto/upload",
      );

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final data = jsonDecode(resStr);
        setState(() {
          uploadedUrl = data['secure_url'];
          isUploading = false;
        });
      } else {
        setState(() => isUploading = false);
        throw Exception("Upload failed: ${response.statusCode}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cloudinary Upload")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: uploadFile,
                icon: const Icon(Icons.upload),
                label: const Text("Select & Upload File"),
              ),
              const SizedBox(height: 20),
              if (isUploading) const CircularProgressIndicator(),
              if (uploadedUrl != null) ...[
                const Text("✅ Uploaded Successfully!"),
                SelectableText(uploadedUrl!),
                ElevatedButton(
                  onPressed: () async {
                    // Download / open file
                  },
                  child: const Text("Download / Open"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
