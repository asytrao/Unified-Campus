import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentQueriesPage extends StatefulWidget {
  final String subject;
  final String department;
  final String year;

  const StudentQueriesPage({
    super.key,
    required this.subject,
    required this.department,
    required this.year,
  });

  @override
  State<StudentQueriesPage> createState() => _StudentQueriesPageState();
}

class _StudentQueriesPageState extends State<StudentQueriesPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _queryController = TextEditingController();

  late final CollectionReference queryCollection;

  @override
  void initState() {
    super.initState();

    final docId = "${widget.department.trim().replaceAll(' ', '')}_${widget.year.trim().replaceAll(' ', '')}";
    final subjectId = widget.subject.trim().replaceAll(' ', '');

    // Matches Firestore structure
    queryCollection = _firestore
        .collection('queries')
        .doc(docId)
        .collection('subjectList')
        .doc(subjectId)
        .collection('queries');
  }

  Future<void> postQuery() async {
    final queryText = _queryController.text.trim();
    if (queryText.isEmpty) return;

    try {
      final user = _auth.currentUser;
      final userDoc = await _firestore.collection('users').doc(user!.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Student';

      await queryCollection.add({
        'question': queryText, // Changed to match professor page's field
        'studentId': user.uid,
        'studentName': userName,
        'isResolved': false,
        'solution': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _queryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error posting query: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.subject} – Your Queries")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: queryCollection.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No queries posted yet."));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final question = data['question'] ?? '';
                    final studentName = data['studentName'] ?? 'Unknown';
                    final isResolved = data['isResolved'] ?? false;
                    final solution = data['solution'] ?? '';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text("by $studentName"),
                            const SizedBox(height: 8),
                            if (isResolved)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "✅ Resolved",
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Solution: $solution"),
                                ],
                              )
                            else
                              const Text(
                                "⏳ Pending resolution",
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: "Type your query...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: postQuery,
                  child: const Text("Send"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
