import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

class NotificationWidget extends StatelessWidget {
  const NotificationWidget({super.key});

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: NotificationService.getUnreadCount(user.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return Stack(
          children: [
            IconButton(
              onPressed: () => _showNotificationsBottomSheet(context, user.uid),
              icon: const Icon(Icons.notifications_outlined),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _markAllAsRead(userId),
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Notifications List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: NotificationService.getUserNotifications(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final notifications = snapshot.data?.docs ?? [];

                    if (notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final doc = notifications[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        return _NotificationTile(
                          notificationId: doc.id,
                          data: data,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);

  const _NotificationTile({
    required this.notificationId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final isRead = data['isRead'] as bool? ?? false;
    final createdAt = data['createdAt'] as Timestamp?;

    return InkWell(
      onTap: () {
        if (!isRead) {
          NotificationService.markAsRead(notificationId);
        }
        _handleNotificationTap(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : _primary.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getTypeIcon(type),
                color: _getTypeColor(type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textDark.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(createdAt.toDate()),
                      style: TextStyle(
                        fontSize: 12,
                        color: _textDark.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'query':
        return Icons.help_outline;
      case 'community':
        return Icons.groups;
      case 'document':
        return Icons.description;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'query':
        return Colors.orange;
      case 'community':
        return Colors.blue;
      case 'document':
        return _primary;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(BuildContext context) {
    final type = data['type'] as String?;
    final relatedId = data['relatedId'] as String?;
    
    // Handle navigation based on notification type
    switch (type) {
      case 'query':
        // Navigate to query details
        break;
      case 'community':
        // Navigate to community chat
        break;
      case 'document':
        // Navigate to document details
        break;
    }
  }
}