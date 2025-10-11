import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CommunityChatPage extends StatefulWidget {
  final String communityId;
  final String communityName;

  const CommunityChatPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Dark theme constants
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Colors.white;
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _background = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser!;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    await _firestore
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': user.uid,
          'senderName': userData['name'] ?? 'Unknown',
          'senderRole': userData['role'] ?? 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });

    _messageController.clear();

    // Auto-scroll to bottom after sending
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = _firestore
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        title: GestureDetector(
          onTap: _showCommunityInfo,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.communityName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Community Chat",
                      style: TextStyle(
                        fontSize: 12,
                        color: _textDark.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FutureBuilder<bool>(
            future: _isCurrentUserAdmin(),
            builder: (context, snapshot) {
              final isAdmin = snapshot.data ?? false;
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'info') {
                    _showCommunityInfo();
                  } else if (value == 'delete' && isAdmin) {
                    _deleteCommunity();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded),
                        SizedBox(width: 8),
                        Text('Community Info'),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Community', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: _textDark.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No messages yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start the conversation!",
                          style: TextStyle(
                            fontSize: 14,
                            color: _textDark.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // newest messages at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _auth.currentUser!.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _MessageBubble(
                        messageId: messages[index].id,
                        text: data['text'] ?? "",
                        imageUrl: data['imageUrl'],
                        senderName: data['senderName'] ?? "Unknown",
                        senderRole: data['senderRole'] ?? 'student',
                        isMe: isMe,
                        timestamp: data['createdAt'] != null
                            ? (data['createdAt'] as Timestamp).toDate()
                            : null,
                        onDelete: isMe ? () => _deleteMessage(messages[index].id) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              border: Border(
                top: BorderSide(color: _textDark.withOpacity(0.1), width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_rounded, color: _primary),
                  onPressed: _sendImage,
                  tooltip: "Send Image",
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _textDark.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: _textDark),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: _textDark.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: sendMessage,
                    tooltip: "Send Message",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    
    try {
      final file = File(pickedFile.path);
      final fileName = 'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();
      
      final user = _auth.currentUser!;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('messages')
          .add({
            'imageUrl': imageUrl,
            'senderId': user.uid,
            'senderName': userData['name'] ?? 'Unknown',
            'senderRole': userData['role'] ?? 'student',
            'createdAt': FieldValue.serverTimestamp(),
          });
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending image: $e')),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Delete Message?', style: TextStyle(color: _textDark)),
        content: const Text(
          'This message will be deleted for everyone.',
          style: TextStyle(color: _textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textDark)),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      try {
        await _firestore
            .collection('communities')
            .doc(widget.communityId)
            .collection('messages')
            .doc(messageId)
            .delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting message: $e')),
        );
      }
    }
  }

  Future<void> _deleteCommunity() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Delete Community?', style: TextStyle(color: _textDark)),
        content: const Text(
          'This will permanently delete the community and all messages. This action cannot be undone.',
          style: TextStyle(color: _textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textDark)),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      try {
        await _firestore.collection('communities').doc(widget.communityId).delete();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Community deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting community: $e')),
        );
      }
    }
  }

  Future<bool> _isCurrentUserAdmin() async {
    try {
      final communityDoc = await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .get();
      final data = communityDoc.data() ?? {};
      final adminIds = List<String>.from(data['admins'] ?? []);
      return adminIds.contains(_auth.currentUser!.uid);
    } catch (e) {
      return false;
    }
  }

  void _showCommunityInfo() async {
    final communityDoc = await _firestore
        .collection('communities')
        .doc(widget.communityId)
        .get();
    final data = communityDoc.data() ?? {};

    final memberIds = List<String>.from(data['members'] ?? []);
    final adminIds = List<String>.from(data['admins'] ?? []);
    final isAdmin = adminIds.contains(_auth.currentUser!.uid);

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _textDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: _primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.communityName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['description'] ?? "Community Chat",
                style: TextStyle(
                  fontSize: 14,
                  color: _textDark.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              
              // Action buttons for admins
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddMembersDialog(),
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text("Add Members"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showInviteLinkDialog(),
                        icon: const Icon(Icons.link_rounded),
                        label: const Text("Invite Link"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _surface,
                          foregroundColor: _textDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildUserList("Admins", adminIds, isAdmin: isAdmin),
                    const SizedBox(height: 16),
                    _buildUserList("Members", memberIds, isAdmin: isAdmin),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(String title, List<String> userIds, {bool isAdmin = false}) {
    if (userIds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title (${userIds.length})",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(
            userIds.map((id) => _firestore.collection('users').doc(id).get()),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final userDocs = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userDocs.length,
              itemBuilder: (context, index) {
                final doc = userDocs[index];
                final userData = doc.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? 'Unknown';
                final role = userData['role'] ?? 'student';
                final rollNumber = userData['rollNumber'];
                final userId = doc.id;
                final isCurrentUser = userId == _auth.currentUser!.uid;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: role == 'professor'
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: role == 'professor' ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(name, style: const TextStyle(color: _textDark)),
                  subtitle: Text(
                    role == 'student' && rollNumber != null
                        ? '$role • Roll: $rollNumber'
                        : role,
                    style: TextStyle(color: _textDark.withOpacity(0.7)),
                  ),
                  trailing: isAdmin && !isCurrentUser && title == "Members"
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              _removeMember(userId);
                            } else if (value == 'make_admin') {
                              _makeAdmin(userId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'make_admin',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded),
                                  SizedBox(width: 8),
                                  Text('Make Admin'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(Icons.person_remove_rounded, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Remove', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : null,
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          "Add Members",
          style: TextStyle(color: _textDark),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _UserSelectionWidget(
            communityId: widget.communityId,
            onMembersAdded: () {
              Navigator.pop(context);
              // Refresh the community info
              _showCommunityInfo();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: _textDark)),
          ),
        ],
      ),
    );
  }

  void _showInviteLinkDialog() {
    final inviteLink = "https://yourapp.com/join/${widget.communityId}";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          "Invite Link",
          style: TextStyle(color: _textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Share this link to invite people to join the community:",
              style: TextStyle(color: _textDark),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primary.withOpacity(0.3)),
              ),
              child: SelectableText(
                inviteLink,
                style: const TextStyle(
                  color: _textDark,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: _textDark)),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied to clipboard!")),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text("Copy Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(String userId) async {
    try {
      await _firestore.collection('communities').doc(widget.communityId).update({
        'members': FieldValue.arrayRemove([userId]),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Member removed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing member: $e")),
      );
    }
  }

  Future<void> _makeAdmin(String userId) async {
    try {
      await _firestore.collection('communities').doc(widget.communityId).update({
        'admins': FieldValue.arrayUnion([userId]),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User promoted to admin")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error promoting user: $e")),
      );
    }
  }
}

// Custom widget for message bubbles
class _MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final String? imageUrl;
  final String senderName;
  final String senderRole;
  final bool isMe;
  final DateTime? timestamp;
  final VoidCallback? onDelete;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Colors.white;
  static const Color _surface = Color(0xFF1A1A1A);

  const _MessageBubble({
    required this.messageId,
    required this.text,
    this.imageUrl,
    required this.senderName,
    required this.senderRole,
    required this.isMe,
    this.timestamp,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: senderRole == 'professor'
                  ? const Color(0xFFE67E22).withOpacity(0.2)
                  : const Color(0xFF4A90E2).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : "?",
                style: TextStyle(
                  color: senderRole == 'professor'
                      ? const Color(0xFFE67E22)
                      : const Color(0xFF4A90E2),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: GestureDetector(
            onLongPress: onDelete,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? _primary : _surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe
                    ? null
                    : Border.all(color: _textDark.withOpacity(0.1), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Row(
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            color: senderRole == 'professor'
                                ? const Color(0xFFE67E22)
                                : const Color(0xFF4A90E2),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (senderRole == 'professor') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE67E22).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "PROF",
                              style: TextStyle(
                                color: Color(0xFFE67E22),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (onDelete != null) ...[
                          const Spacer(),
                          Icon(
                            Icons.more_vert,
                            size: 12,
                            color: _textDark.withOpacity(0.5),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ] else if (onDelete != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.more_vert,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 100,
                            color: Colors.grey.withOpacity(0.3),
                            child: const Icon(Icons.error, color: Colors.red),
                          );
                        },
                      ),
                    ),
                    if (text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : _textDark,
                        fontSize: 14,
                      ),
                    ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(timestamp!),
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : _textDark.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: const Icon(
                Icons.person_rounded,
                color: _primary,
                size: 16,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

// User Selection Widget for adding members
class _UserSelectionWidget extends StatefulWidget {
  final String communityId;
  final VoidCallback onMembersAdded;

  const _UserSelectionWidget({
    required this.communityId,
    required this.onMembersAdded,
  });

  @override
  State<_UserSelectionWidget> createState() => _UserSelectionWidgetState();
}

class _UserSelectionWidgetState extends State<_UserSelectionWidget> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  List<String> _selectedUsers = [];
  List<DocumentSnapshot> _allUsers = [];
  List<DocumentSnapshot> _filteredUsers = [];
  bool _isLoading = true;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Colors.white;
  static const Color _surface = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      // Get current community members
      final communityDoc = await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .get();
      final communityData = communityDoc.data() ?? {};
      final currentMembers = List<String>.from(communityData['members'] ?? []);
      final currentAdmins = List<String>.from(communityData['admins'] ?? []);
      final allCurrentUsers = [...currentMembers, ...currentAdmins];

      // Get all users except current community members
      final usersSnapshot = await _firestore.collection('users').get();
      _allUsers = usersSnapshot.docs
          .where((doc) => !allCurrentUsers.contains(doc.id))
          .toList();
      
      _filteredUsers = List.from(_allUsers);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading users: $e")),
      );
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final name = (data['name'] ?? '').toLowerCase();
        final email = (data['email'] ?? '').toLowerCase();
        final role = (data['role'] ?? '').toLowerCase();
        return name.contains(query) || email.contains(query) || role.contains(query);
      }).toList();
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  Future<void> _addSelectedUsers() async {
    if (_selectedUsers.isEmpty) return;

    try {
      await _firestore.collection('communities').doc(widget.communityId).update({
        'members': FieldValue.arrayUnion(_selectedUsers),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_selectedUsers.length} members added successfully")),
      );
      widget.onMembersAdded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding members: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          style: const TextStyle(color: _textDark),
          decoration: InputDecoration(
            hintText: "Search users...",
            hintStyle: TextStyle(color: _textDark.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.search, color: _textDark),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _textDark.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Selected users count
        if (_selectedUsers.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: _primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "${_selectedUsers.length} user(s) selected",
                  style: TextStyle(color: _primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
        // Users list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final doc = _filteredUsers[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final userId = doc.id;
              final name = data['name'] ?? 'Unknown';
              final email = data['email'] ?? '';
              final role = data['role'] ?? 'student';
              final rollNumber = data['rollNumber'];
              final isSelected = _selectedUsers.contains(userId);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => _toggleUserSelection(userId),
                title: Text(name, style: const TextStyle(color: _textDark)),
                subtitle: Text(
                  role == 'student' && rollNumber != null
                      ? "$email • $role • Roll: $rollNumber"
                      : "$email • $role",
                  style: TextStyle(color: _textDark.withOpacity(0.7)),
                ),
                secondary: CircleAvatar(
                  backgroundColor: role == 'professor'
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: role == 'professor' ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Add button
        if (_selectedUsers.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addSelectedUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Add ${_selectedUsers.length} Member(s)"),
            ),
          ),
      ],
    );
  }
}
