import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class StudentSubmissionsPage extends StatefulWidget {
  final String subject;
  final String department;
  final String year;

  const StudentSubmissionsPage({
    super.key,
    required this.subject,
    required this.department,
    required this.year,
  });

  @override
  State<StudentSubmissionsPage> createState() => _StudentSubmissionsPageState();
}

class _StudentSubmissionsPageState extends State<StudentSubmissionsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Cloudinary details
  final String cloudName = "dzxbqfatf";
  final String uploadPreset = "unisgned_preset";

  late final CollectionReference contentCollection;
  late final String studentId;
  bool _uploading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    studentId = _auth.currentUser!.uid;

    final docId =
        "${widget.department.trim().replaceAll(' ', '')}_${widget.year.trim().replaceAll(' ', '')}";
    final subjectId = widget.subject.trim().replaceAll(' ', '');

    contentCollection = _firestore
        .collection('subjects')
        .doc(docId)
        .collection('subjectList')
        .doc(subjectId)
        .collection('content');
  }

  Future<void> _pickAndUploadFile(String contentId) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      final file = File(filePath);

      setState(() {
        _uploading = true;
        _progress = 0.0;
      });

      // Upload to Cloudinary
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) {
        throw Exception("Upload failed: ${response.body}");
      }

      final responseData = json.decode(response.body);
      final downloadUrl = responseData['secure_url'];

      // Save submission info in Firestore
      await contentCollection
          .doc(contentId)
          .collection('submissions')
          .doc(studentId)
          .set({
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = 0.0;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Submission uploaded successfully")),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = 0.0;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.subject} – Submissions")),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: contentCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No tasks assigned yet."));
              }

              final contents = snapshot.data!.docs;

              return ListView.builder(
                itemCount: contents.length,
                itemBuilder: (context, index) {
                  final content = contents[index];
                  final data = content.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Untitled';
                  final description = data['description'] ?? '';
                  final dueDate = data['dueDate'] != null
                      ? (data['dueDate'] as Timestamp).toDate()
                      : null;

                  return StreamBuilder<DocumentSnapshot>(
                    stream: contentCollection
                        .doc(content.id)
                        .collection('submissions')
                        .doc(studentId)
                        .snapshots(),
                    builder: (context, submissionSnapshot) {
                      bool isSubmitted = submissionSnapshot.hasData &&
                          submissionSnapshot.data!.exists;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: ListTile(
                          title: Text(title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description.isNotEmpty) Text(description),
                              if (dueDate != null)
                                Text(
                                  "Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}",
                                  style: const TextStyle(
                                      color: Colors.redAccent),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                isSubmitted
                                    ? "✅ Submitted"
                                    : "⏳ Not submitted yet",
                                style: TextStyle(
                                  color: isSubmitted
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: _uploading
                                ? null
                                : () => _pickAndUploadFile(content.id),
                            child: Text(isSubmitted ? "Resubmit" : "Submit"),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          if (_uploading)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("Uploading..."),
                      SizedBox(height: 8),
                      LinearProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
