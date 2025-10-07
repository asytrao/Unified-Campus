import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

class UploadDocumentsPage extends StatefulWidget {
  const UploadDocumentsPage({super.key});

  @override
  State<UploadDocumentsPage> createState() => _UploadDocumentsPageState();
}

class _UploadDocumentsPageState extends State<UploadDocumentsPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedSubject;
  String? _selectedYear;
  File? _selectedFile;
  bool _isUploading = false;
  
  List<String> _subjects = [];
  List<String> _years = [];
  
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);

  @override
  void initState() {
    super.initState();
    _loadSubjectsAndYears();
  }

  Future<void> _loadSubjectsAndYears() async {
    try {
      // Load subjects
      final subjectsSnapshot = await _firestore.collection('subjects').get();
      _subjects = subjectsSnapshot.docs.map((doc) => doc['name'] as String).toList();
      
      // Load years
      _years = ['First Year', 'Second Year', 'Third Year', 'Fourth Year'];
      
      setState(() {});
    } catch (e) {
      print('Error loading subjects and years: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'ppt', 'pptx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a file')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = _auth.currentUser!;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}';
      
      // Upload file to Firebase Storage
      final ref = _storage.ref().child('documents/$fileName');
      final uploadTask = ref.putFile(_selectedFile!);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Save document metadata to Firestore
      await _firestore.collection('documents').add({
        'name': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'url': downloadUrl,
        'fileName': _selectedFile!.path.split('/').last,
        'subject': _selectedSubject,
        'year': _selectedYear,
        'uploadedBy': user.uid,
        'uploaderName': userData['name'] ?? 'Unknown',
        'uploaderEmail': userData['email'] ?? '',
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
      });

      // Send notification to professors
      await _notifyProfessors();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully! Awaiting approval.'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedFile = null;
        _selectedSubject = null;
        _selectedYear = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _notifyProfessors() async {
    try {
      // Get all professors
      final professorsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'professor')
          .get();

      // Send notification to each professor
      for (final doc in professorsSnapshot.docs) {
        await NotificationService.sendDocumentNotification(
          userId: doc.id,
          documentId: 'pending', // Will be updated with actual ID
          action: 'uploaded',
          documentName: _titleController.text.trim(),
        );
      }
    } catch (e) {
      print('Error notifying professors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Upload Document'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cloud_upload,
                            color: _primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload Document',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                              Text(
                                'Share your documents with the community',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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

              // Form Fields
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title',
                        hintText: 'Enter document title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Enter document description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subject Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subject),
                      ),
                      items: _subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a subject';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Year Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Academic Year',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      items: _years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an academic year';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // File Picker
                    InkWell(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedFile != null ? _primary : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedFile != null 
                              ? _primary.withOpacity(0.05) 
                              : Colors.grey.withOpacity(0.05),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                              size: 48,
                              color: _selectedFile != null ? _primary : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFile != null 
                                  ? _selectedFile!.path.split('/').last
                                  : 'Tap to select file',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _selectedFile != null ? _primary : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedFile == null) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Supported: PDF, DOC, DOCX, JPG, PNG, PPT, PPTX',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadDocument,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isUploading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Uploading...'),
                                ],
                              )
                            : const Text(
                                'Upload Document',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}