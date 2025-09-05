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

  // Dark theme constants
  static const Color _primary = Color(0xFF00D4AA);
  static const Color _primaryDark = Color(0xFF00B894);
  static const Color _background = Color(0xFF0A0A0A);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _surfaceVariant = Color(0xFF2A2A2A);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFB0B0B0);
  static const Color _textTertiary = Color(0xFF808080);
  static const Color _accentBlue = Color(0xFF4A90E2);
  static const Color _accentPurple = Color(0xFF9B59B6);
  static const Color _accentOrange = Color(0xFFE67E22);
  static const Color _accentGreen = Color(0xFF27AE60);
  static const Color _accentRed = Color(0xFFE74C3C);

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
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/auto/upload",
      );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Upload failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.subject} Submissions',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                fontSize: 20,
              ),
            ),
            Text(
              '${widget.year} • ${widget.department}',
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: contentCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primary),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 40,
                          color: _textTertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No assignments yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your professor will add assignments here",
                        style: TextStyle(fontSize: 14, color: _textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final contents = snapshot.data!.docs;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primary, _primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.assignment_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Your Assignments",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Text(
                                      "Submit your work here",
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Assignments List
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Assignments (${contents.length})',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ...contents.map((content) {
                      final data = content.data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'Untitled';
                      final description = data['description'] ?? '';
                      final type = data['type'] ?? 'Assignment';
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
                          bool isSubmitted =
                              submissionSnapshot.hasData &&
                              submissionSnapshot.data!.exists;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: _AssignmentCard(
                              title: title,
                              description: description,
                              type: type,
                              dueDate: dueDate,
                              isSubmitted: isSubmitted,
                              onTap: _uploading
                                  ? null
                                  : () => _pickAndUploadFile(content.id),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          if (_uploading)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _surfaceVariant, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_primary),
                          strokeWidth: 2,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Uploading your file...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                      backgroundColor: _surfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom widget for assignment cards
class _AssignmentCard extends StatelessWidget {
  final String title;
  final String description;
  final String type;
  final DateTime? dueDate;
  final bool isSubmitted;
  final VoidCallback? onTap;

  const _AssignmentCard({
    required this.title,
    required this.description,
    required this.type,
    this.dueDate,
    required this.isSubmitted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'Assignment':
        typeColor = const Color(0xFF4A90E2);
        typeIcon = Icons.assignment_rounded;
        break;
      case 'Practical':
        typeColor = const Color(0xFF27AE60);
        typeIcon = Icons.science_rounded;
        break;
      case 'Notes':
        typeColor = const Color(0xFFE67E22);
        typeIcon = Icons.note_rounded;
        break;
      case 'Project':
        typeColor = const Color(0xFF9B59B6);
        typeIcon = Icons.work_rounded;
        break;
      default:
        typeColor = const Color(0xFF808080);
        typeIcon = Icons.menu_book_rounded;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? const Color(0xFF27AE60).withOpacity(0.2)
                        : const Color(0xFFE67E22).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSubmitted ? "Submitted" : "Pending",
                    style: TextStyle(
                      color: isSubmitted
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFE67E22),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
              ),
            ],

            if (dueDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: const Color(0xFFE74C3C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE74C3C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(
                  isSubmitted ? Icons.upload_rounded : Icons.upload_rounded,
                  size: 18,
                ),
                label: Text(isSubmitted ? "Resubmit" : "Submit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
