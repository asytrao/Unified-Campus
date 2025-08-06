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

    print("🔍 DEBUG: Initialize ManageSubjectContentPage");
    print("   📍 Department: ${widget.department}");
    print("   📍 Year: ${widget.year}");
    print("   📍 Subject: ${widget.subject}");
    print("   📍 Doc ID: $docId");
    print("   📍 Subject ID: $subjectId");
    print("   📍 Full Firestore Path: subjects/$docId/subjectList/$subjectId");
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
      print("📌 DEBUG: Adding content");
      print("   📍 Target Path: subjects/$docId/subjectList/$subjectId");
      print("   📍 Content Title: $title");
      print("   📍 Content Type: $selectedType");

      // First, ensure the subject document exists
      await subjectDoc.set({
        'name': widget.subject,
        'year': widget.year,
        'department': widget.department,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ DEBUG: Subject document created/updated successfully");

      // Add content to the content subcollection
      final contentRef = await subjectDoc.collection('content').add({
        'title': title,
        'description': desc,
        'type': selectedType,
        'createdAt': FieldValue.serverTimestamp(),
        'subjectId': subjectId,
        'docId': docId,
      });

      print("✅ DEBUG: Content added successfully");
      print("   📍 Content ID: ${contentRef.id}");
      print(
        "   📍 Full Content Path: subjects/$docId/subjectList/$subjectId/content/${contentRef.id}",
      );

      _titleController.clear();
      _descController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Content added successfully")),
      );
    } catch (e) {
      print("❌ DEBUG: Error adding content");
      print("   📍 Error: $e");
      print("   📍 Error Type: ${e.runtimeType}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error adding content: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} – Manage Content"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              print("🔍 DEBUG: Current Firestore Paths");
              print("   📍 Doc ID: $docId");
              print("   📍 Subject ID: $subjectId");
              print(
                "   📍 Subject Path: subjects/$docId/subjectList/$subjectId",
              );
              print(
                "   📍 Content Path: subjects/$docId/subjectList/$subjectId/content",
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Debug info logged. Check console for paths."),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: "Debug Info",
          ),
        ],
      ),
      body: Column(
        children: [
          // Input Form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    DropdownMenuItem(
                      value: "Assignment",
                      child: Text("Assignment"),
                    ),
                    DropdownMenuItem(
                      value: "Practical",
                      child: Text("Practical"),
                    ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  "📌 Added Content",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  "(${widget.subject})",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: subjectDoc
                  .collection('content')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print("❌ DEBUG: Stream error: ${snapshot.error}");
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text("Error loading content: ${snapshot.error}"),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No content added yet."),
                        Text(
                          "Add your first piece of content above!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                print(
                  "📊 DEBUG: Loaded ${docs.length} content items for subject: ${widget.subject}",
                );

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${data['type']} • ${data['description'] ?? ''}",
                            ),
                            if (data['createdAt'] != null)
                              Text(
                                "Created: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 19)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            try {
                              await docs[index].reference.delete();
                              print(
                                "🗑️ DEBUG: Content deleted: ${docs[index].id}",
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("🗑️ Content deleted"),
                                ),
                              );
                            } catch (e) {
                              print("❌ DEBUG: Error deleting content: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("❌ Error deleting: $e")),
                              );
                            }
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
