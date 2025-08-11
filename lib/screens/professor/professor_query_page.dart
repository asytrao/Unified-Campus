import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessorQueryPage extends StatelessWidget {
  final String subject;
  final String year;
  final String department;

  const ProfessorQueryPage({
    super.key,
    required this.subject,
    required this.year,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    final docId =
        "${department.trim().replaceAll(' ', '')}_${year.trim().replaceAll(' ', '')}";
    final queryRef = FirebaseFirestore.instance
        .collection('queries')
        .doc(docId)
        .collection('subjectList')
        .doc(subject.trim().replaceAll(' ', ''))
        .collection('queries')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Queries - $subject'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: queryRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No queries found."));
          }

          final queries = snapshot.data!.docs;

          return ListView.builder(
            itemCount: queries.length,
            itemBuilder: (context, index) {
              final data = queries[index].data() as Map<String, dynamic>;
              final docRef = queries[index].reference;

              final studentName = data['studentName'] ?? 'Unknown';
              final question = data['question'] ?? '';
              final isResolved = data['isResolved'] ?? false;
              final solution = data['solution'] ?? '';

              final solutionController = TextEditingController(text: solution);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Student: $studentName",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text("Query: $question"),
                      const SizedBox(height: 12),
                      if (isResolved)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Solution:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(solution.isNotEmpty ? solution : "No solution provided"),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 6),
                                const Text("Resolved", style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            TextField(
                              controller: solutionController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: "Type your solution...",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text("Resolve Query"),
                              onPressed: () async {
                                final sol = solutionController.text.trim();
                                await docRef.update({
                                  'solution': sol,
                                  'isResolved': true,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("✅ Query marked as resolved")),
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
