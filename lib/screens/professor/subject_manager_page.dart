import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectManagerPage extends StatefulWidget {
  const SubjectManagerPage({super.key});

  @override
  State<SubjectManagerPage> createState() => _SubjectManagerPageState();
}

class _SubjectManagerPageState extends State<SubjectManagerPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? department;
  String? selectedYear;
  List<String> subjects = [];
  bool loading = true;
  bool _isSaving = false;
  final _subjectController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> defaultYears = ["First Year", "Second Year", "Third Year"];
  List<String> allYears = [];

  // Design constants matching other professor pages
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);
  static const Color _accentBlue = Color(0xFFD6EBFB);
  static const Color _accentGreen = Color(0xFFCFF3E6);
  static const Color _accentOrange = Color(0xFFFBE3C8);

  @override
  void initState() {
    super.initState();
    fetchProfessorDepartmentAndYears();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> fetchProfessorDepartmentAndYears() async {
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      department = userDoc['department'];

      // Fetch custom years for this department
      final deptDoc = await _firestore
          .collection('departments')
          .doc(department)
          .get();
      List<String> customYears = [];
      if (deptDoc.exists) {
        final deptData = deptDoc.data() as Map<String, dynamic>;
        customYears = List<String>.from(deptData['years'] ?? []);
      }

      // Merge default and custom years
      allYears = [
        ...defaultYears,
        ...customYears.where((y) => !defaultYears.contains(y)),
      ];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading department/years: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchSubjects() async {
    if (department == null || selectedYear == null) return;

    final docId =
        "${department!.trim().replaceAll(' ', '')}_${selectedYear!.trim().replaceAll(' ', '')}";
    final subjectListRef = _firestore
        .collection('subjects')
        .doc(docId)
        .collection('subjectList');

    try {
      final querySnapshot = await subjectListRef.get();
      setState(() {
        subjects = querySnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading subjects: $e")));
    }
  }

  Future<void> saveSubjects() async {
    if (department == null || selectedYear == null) return;

    setState(() => _isSaving = true);

    final docId =
        "${department!.trim().replaceAll(' ', '')}_${selectedYear!.trim().replaceAll(' ', '')}";
    final subjectListRef = _firestore
        .collection('subjects')
        .doc(docId)
        .collection('subjectList');

    try {
      for (final subject in subjects) {
        final subjectId = subject.trim().replaceAll(' ', '');
        await subjectListRef.doc(subjectId).set({
          'name': subject,
          'year': selectedYear,
          'department': department,
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Subjects updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving subjects: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void addSubject() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final subject = _subjectController.text.trim();
    if (subject.isNotEmpty && !subjects.contains(subject)) {
      setState(() {
        subjects.add(subject);
        _subjectController.clear();
      });
    }
  }

  Future<void> deleteSubject(String subject) async {
    if (department == null || selectedYear == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete subject?'),
          content: Text(
            'Are you sure you want to delete "$subject"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final docId =
        "${department!.trim().replaceAll(' ', '')}_${selectedYear!.trim().replaceAll(' ', '')}";
    final subjectListRef = _firestore
        .collection('subjects')
        .doc(docId)
        .collection('subjectList');

    try {
      final subjectId = subject.trim().replaceAll(' ', '');
      await subjectListRef.doc(subjectId).delete();
      setState(() {
        subjects.remove(subject);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("🗑️ $subject deleted")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting subject: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Subject Manager",
              style: TextStyle(fontWeight: FontWeight.w700, color: _textDark),
            ),
            if (department != null)
              Text(
                department!,
                style: TextStyle(
                  fontSize: 12,
                  color: _textDark.withOpacity(0.65),
                ),
              ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Year selector card
                  Container(
                    padding: const EdgeInsets.all(16),
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Select Academic Year',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedYear,
                          items: allYears
                              .map(
                                (y) =>
                                    DropdownMenuItem(value: y, child: Text(y)),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: "Academic Year",
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value;
                            });
                            fetchSubjects();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Add subject card
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add New Subject',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              labelText: 'Subject Name',
                              prefixIcon: const Icon(Icons.menu_book),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: addSubject,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                ? 'Subject name is required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subjects list
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.list_alt,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Subjects (${subjects.length})",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (subjects.isEmpty)
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu_book_outlined,
                                      size: 64,
                                      color: _textDark.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No subjects added",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _textDark.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Add subjects using the form above",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _textDark.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.separated(
                                itemCount: subjects.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final subject = subjects[index];
                                  return _SubjectTile(
                                    subject: subject,
                                    onDelete: () => deleteSubject(subject),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : saveSubjects,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? "Saving..." : "Save Changes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

class _SubjectTile extends StatelessWidget {
  final String subject;
  final VoidCallback onDelete;

  static const Color _textDark = Color(0xFF2C3E50);

  const _SubjectTile({required this.subject, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2EC4B6).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.menu_book, color: Color(0xFF2EC4B6)),
      ),
      title: Text(
        subject,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: onDelete,
        tooltip: 'Delete subject',
      ),
    );
  }
}
