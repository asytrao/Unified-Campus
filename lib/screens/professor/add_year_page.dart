import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddYearSectionPage extends StatefulWidget {
  const AddYearSectionPage({super.key});

  @override
  State<AddYearSectionPage> createState() => _AddYearSectionPageState();
}

class _AddYearSectionPageState extends State<AddYearSectionPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final List<String> years = ["First Year", "Second Year", "Third Year"];
  String? selectedYear;
  String? department;
  List<String> subjects = [];
  final _subjectController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfessorDepartment();
  }

  Future<void> fetchProfessorDepartment() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      department = doc['department'];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching department: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
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

  void removeSubject(String subject) {
    setState(() {
      subjects.remove(subject);
    });
  }

  Future<void> saveSection() async {
    if (selectedYear == null || department == null || subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final docId = "${department}_$selectedYear";
    await _firestore.collection('subjects').doc(docId).set({
      'subjects': subjects,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ $selectedYear section added for $department")),
    );

    Navigator.pop(context); // Go back to ProfessorHomePage
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Add Year Section')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedYear,
              items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (val) => setState(() => selectedYear = val),
              decoration: const InputDecoration(labelText: "Select Year"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: "Add Subject",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addSubject,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return ListTile(
                    title: Text(subject),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => removeSubject(subject),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: saveSection,
              icon: const Icon(Icons.save),
              label: const Text("Save Year Section"),
            )
          ],
        ),
      ),
    );
  }
}
