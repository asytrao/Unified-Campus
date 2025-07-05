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
  final _subjectController = TextEditingController();

  final List<String> defaultYears = ["First Year", "Second Year", "Third Year"];
  List<String> allYears = [];

  @override
  void initState() {
    super.initState();
    fetchProfessorDepartmentAndYears();
  }

  Future<void> fetchProfessorDepartmentAndYears() async {
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      department = userDoc['department'];
      // Fetch custom years from Firestore
      final deptDoc = await _firestore
          .collection('departments')
          .doc(department)
          .get();
      List<String> customYears = [];
      if (deptDoc.exists) {
        final deptData = deptDoc.data() as Map<String, dynamic>;
        customYears = List<String>.from(deptData['years'] ?? []);
      }
      // Merge default and custom years, avoiding duplicates
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
    print("Fetching subjects from: $docId");

    try {
      final doc = await _firestore.collection('subjects').doc(docId).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          subjects = List<String>.from(data?['subjects'] ?? []);
        });
      } else {
        setState(() {
          subjects = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading subjects: $e")));
    }
  }

  Future<void> saveSubjects() async {
    if (department == null || selectedYear == null) return;

    final docId =
        "${department!.trim().replaceAll(' ', '')}_${selectedYear!.trim().replaceAll(' ', '')}";
    print("Saving subjects to: $docId");

    await _firestore.collection('subjects').doc(docId).set({
      'subjects': subjects,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Subjects updated successfully")),
    );
  }

  void addSubject() {
    final subject = _subjectController.text.trim();
    if (subject.isNotEmpty && !subjects.contains(subject)) {
      setState(() {
        subjects.add(subject);
        _subjectController.clear();
      });
    }
  }

  void deleteSubject(String subject) {
    setState(() {
      subjects.remove(subject);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subject Manager")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedYear,
                    items: allYears
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: "Select Year",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                      });
                      fetchSubjects();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Add New Subject',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: addSubject,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "📚 Subjects:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        return Card(
                          child: ListTile(
                            title: Text(subject),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteSubject(subject),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: saveSubjects,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Changes"),
                  ),
                ],
              ),
            ),
    );
  }
}
