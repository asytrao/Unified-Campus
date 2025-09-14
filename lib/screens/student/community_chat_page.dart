import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showCommunityInfo,
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
                        text: data['text'] ?? "",
                        senderName: data['senderName'] ?? "Unknown",
                        senderRole: data['senderRole'] ?? 'student',
                        isMe: isMe,
                        timestamp: data['createdAt'] != null
                            ? (data['createdAt'] as Timestamp).toDate()
                            : null,
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

  void _showCommunityInfo() async {
    final communityDoc = await _firestore
        .collection('communities')
        .doc(widget.communityId)
        .get();
    final data = communityDoc.data() ?? {};

    final members = data['members'] as Map<String, dynamic>? ?? {};
    final admins = data['admins'] as Map<String, dynamic>? ?? {};

    final memberIds = members.keys.toList();
    final adminIds = admins.keys.toList();

    // Fetch user details for members and admins
    final memberDocs = await Future.wait(
      memberIds.map((id) => _firestore.collection('users').doc(id).get()),
    );
    final adminDocs = await Future.wait(
      adminIds.map((id) => _firestore.collection('users').doc(id).get()),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
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
                "Community Chat",
                style: TextStyle(
                  fontSize: 14,
                  color: _textDark.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Members",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              ...memberDocs.map((doc) {
                final userData = doc.data() ?? {};
                final name = userData['name'] ?? 'Unknown';
                final role = userData['role'] ?? 'student';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: role == 'professor'
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text(role),
                );
              }),
              const SizedBox(height: 20),
              Text(
                "Admins",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              ...adminDocs.map((doc) {
                final userData = doc.data() ?? {};
                final name = userData['name'] ?? 'Unknown';
                final role = userData['role'] ?? 'student';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: role == 'professor'
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text(role),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom widget for message bubbles
class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final String senderRole;
  final bool isMe;
  final DateTime? timestamp;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Colors.white;
  static const Color _surface = Color(0xFF1A1A1A);

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.senderRole,
    required this.isMe,
    this.timestamp,
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
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
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
