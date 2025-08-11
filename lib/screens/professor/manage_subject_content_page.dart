import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageSubjectContentPage extends StatefulWidget {
  final String subject;
  final String year;
  final String department;

  const ManageSubjectContentPage({
    super.key,
    required this.subject,
    required this.year,
    required this.department,
  });

  @override
  State<ManageSubjectContentPage> createState() =>
      _ManageSubjectContentPageState();
}

class _ManageSubjectContentPageState extends State<ManageSubjectContentPage> {
  final _firestore = FirebaseFirestore.instance;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String selectedType = "Assignment";

  late final DocumentReference subjectDoc;
  late final String docId;
  late final String subjectId;

  @override
  void initState() {
    super.initState();
    docId =
        "${widget.department.trim().replaceAll(' ', '')}_${widget.year.trim().replaceAll(' ', '')}";
    subjectId = widget.subject.trim().replaceAll(' ', '');

    subjectDoc = _firestore
        .collection('subjects')
        .doc(docId)
        .collection('subjectList')
        .doc(subjectId);
  }

  Future<void> addContent() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }

    try {
      await subjectDoc.set({
        'name': widget.subject,
        'year': widget.year,
        'department': widget.department,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final contentRef = await subjectDoc.collection('content').add({
        'title': title,
        'description': desc,
        'type': selectedType,
        'createdAt': FieldValue.serverTimestamp(),
        'subjectId': subjectId,
        'docId': docId,
      });

      _titleController.clear();
      _descController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Content added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error adding content: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} – Manage Content"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: "Assignment", child: Text("Assignment")),
                    DropdownMenuItem(value: "Practical", child: Text("Practical")),
                    DropdownMenuItem(value: "Notes", child: Text("Notes")),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedType = value);
                  },
                  decoration: const InputDecoration(
                    labelText: "Type",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Add Content"),
                  onPressed: addContent,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: subjectDoc
                  .collection('content')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No content added yet."));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final contentId = docs[index].id;
                    return Card(
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Text("${data['type']} • ${data['description'] ?? ''}"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContentSubmissionStatusPage(
                                department: widget.department,
                                year: widget.year,
                                contentId: contentId,
                                contentTitle: data['title'] ?? '',
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await docs[index].reference.delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ContentSubmissionStatusPage extends StatelessWidget {
  final String department;
  final String year;
  final String contentId;
  final String contentTitle;

  const ContentSubmissionStatusPage({
    super.key,
    required this.department,
    required this.year,
    required this.contentId,
    required this.contentTitle,
  });

  @override
  Widget build(BuildContext context) {
    final studentsRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year);

    final submissionsRef = FirebaseFirestore.instance
        .collection('submissions')
        .doc(contentId)
        .collection('studentSubmissions');

    return Scaffold(
      appBar: AppBar(title: Text("Submissions – $contentTitle")),
      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, studentsSnapshot) {
          if (!studentsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = studentsSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: submissionsRef.snapshots(),
            builder: (context, submissionsSnapshot) {
              if (!submissionsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final submissions = submissionsSnapshot.data!.docs;
              final submittedIds = submissions.map((s) => s.id).toSet();

              final submitted = students.where((s) => submittedIds.contains(s.id)).toList();
              final notSubmitted = students.where((s) => !submittedIds.contains(s.id)).toList();

              final percentage = students.isEmpty
                  ? 0
                  : ((submitted.length / students.length) * 100).round();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text("📊 Submission Rate: $percentage%"),
                    const SizedBox(height: 16),
                    Text("✅ Submitted (${submitted.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...submitted.map((s) => ListTile(title: Text(s['name'] ?? 'Unknown'))),
                    const SizedBox(height: 16),
                    Text("❌ Not Submitted (${notSubmitted.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...notSubmitted.map((s) => ListTile(title: Text(s['name'] ?? 'Unknown'))),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
