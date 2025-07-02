import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectManagerPage extends StatefulWidget {
  final String year;
  const SubjectManagerPage({super.key, required this.year});

  @override
  State<SubjectManagerPage> createState() => _SubjectManagerPageState();
}

class _SubjectManagerPageState extends State<SubjectManagerPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? department;
  List<String> subjects = [];
  bool loading = true;
  final TextEditingController _subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      department = userDoc['department'];

      final docId = "${department}_${widget.year}";
      final doc = await _firestore.collection('subjects').doc(docId).get();

      if (doc.exists) {
        subjects = List<String>.from(doc['subjects'] ?? []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching subjects: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveSubjects() async {
    if (department == null) return;

    final docId = "${department}_${widget.year}";
    await _firestore.collection('subjects').doc(docId).set({
      'subjects': subjects,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Subjects updated")),
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
      appBar: AppBar(title: Text('${widget.year} – Subject Manager')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Add New Subject',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: addSubject,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("📚 Subjects:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  )
                ],
              ),
            ),
    );
  }
}
