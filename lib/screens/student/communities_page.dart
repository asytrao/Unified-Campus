import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_chat_page.dart';

class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key});

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? department, year, uid;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      final data = userDoc.data()!;
      uid = _auth.currentUser!.uid;
      department = data['department'];
      year = data['year'];

      // ensure class group exists
      await createClassGroupIfNotExists();

      setState(() => loading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading communities: $e")),
      );
      setState(() => loading = false);
    }
  }

  Future<void> createClassGroupIfNotExists() async {
    if (department == null || year == null) return;

    final groupId = "${department!.trim()}_${year!.trim()}";
    final groupRef = _firestore.collection('communities').doc(groupId);

    final snapshot = await groupRef.get();
    if (!snapshot.exists) {
      await groupRef.set({
        'name': "$year - $department Class Group",
        'createdAt': FieldValue.serverTimestamp(),
        'isClassGroup': true,
        'members': [],
        'admins': [],
      });
    }

    // add current student to the members list
    await groupRef.update({
      'members': FieldValue.arrayUnion([uid])
    });
  }

  Future<void> createNewCommunity() async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Community"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Community name"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Create"),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final docRef = await _firestore.collection('communities').add({
                  'name': name,
                  'createdAt': FieldValue.serverTimestamp(),
                  'isClassGroup': false,
                  'members': [uid],
                  'admins': [uid],
                });
                Navigator.pop(context);
                // Navigate directly to chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommunityChatPage(
                      communityId: docRef.id,
                      communityName: name,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Communities"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Create Community",
            onPressed: createNewCommunity,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('communities')
            .where('members', arrayContains: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final communities = snapshot.data!.docs;

          if (communities.isEmpty) {
            return const Center(
              child: Text("No communities yet. Create one!"),
            );
          }

          return ListView.builder(
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final data = communities[index].data() as Map<String, dynamic>;
              final communityId = communities[index].id;
              final name = data['name'] ?? "Unnamed Community";

              return Card(
                child: ListTile(
                  title: Text(name),
                  leading: const Icon(Icons.group),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityChatPage(
                          communityId: communityId,
                          communityName: name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
