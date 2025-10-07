import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize notifications
  static Future<void> initialize() async {
    await _messaging.requestPermission();
    String? token = await _messaging.getToken();
    if (token != null) {
      // Store token in user document for targeted notifications
      await _storeUserToken(token);
    }
  }

  static Future<void> _storeUserToken(String token) async {
    try {
      final user = await _firestore.collection('users').doc('currentUserId').get();
      if (user.exists) {
        await user.reference.update({'fcmToken': token});
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  // Send notification for query actions
  static Future<void> sendQueryNotification({
    required String userId,
    required String queryId,
    required String action, // 'added', 'resolved', 'replied'
    required String queryTitle,
    String? additionalInfo,
  }) async {
    await _createNotification(
      userId: userId,
      title: _getQueryNotificationTitle(action),
      body: _getQueryNotificationBody(action, queryTitle, additionalInfo),
      type: 'query',
      relatedId: queryId,
      data: {
        'action': action,
        'queryId': queryId,
        'queryTitle': queryTitle,
      },
    );
  }

  // Send notification for community actions
  static Future<void> sendCommunityNotification({
    required String userId,
    required String communityId,
    required String action, // 'added_to_community', 'new_message', 'new_member'
    required String communityName,
    String? senderName,
    String? messagePreview,
  }) async {
    await _createNotification(
      userId: userId,
      title: _getCommunityNotificationTitle(action, communityName),
      body: _getCommunityNotificationBody(action, communityName, senderName, messagePreview),
      type: 'community',
      relatedId: communityId,
      data: {
        'action': action,
        'communityId': communityId,
        'communityName': communityName,
        'senderName': senderName,
      },
    );
  }

  // Send notification for document actions
  static Future<void> sendDocumentNotification({
    required String userId,
    required String documentId,
    required String action, // 'uploaded', 'approved', 'rejected'
    required String documentName,
    String? professorName,
    String? rejectionReason,
  }) async {
    await _createNotification(
      userId: userId,
      title: _getDocumentNotificationTitle(action),
      body: _getDocumentNotificationBody(action, documentName, professorName, rejectionReason),
      type: 'document',
      relatedId: documentId,
      data: {
        'action': action,
        'documentId': documentId,
        'documentName': documentName,
        'professorName': professorName,
      },
    );
  }

  // Create notification in Firestore
  static Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String relatedId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get user notifications
  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Helper methods for notification titles and bodies
  static String _getQueryNotificationTitle(String action) {
    switch (action) {
      case 'added':
        return 'New Query Posted';
      case 'resolved':
        return 'Query Resolved';
      case 'replied':
        return 'New Reply to Your Query';
      default:
        return 'Query Update';
    }
  }

  static String _getQueryNotificationBody(String action, String queryTitle, String? additionalInfo) {
    switch (action) {
      case 'added':
        return 'A new query "$queryTitle" has been posted';
      case 'resolved':
        return 'Your query "$queryTitle" has been resolved';
      case 'replied':
        return 'Someone replied to your query "$queryTitle"';
      default:
        return 'Update on query "$queryTitle"';
    }
  }

  static String _getCommunityNotificationTitle(String action, String communityName) {
    switch (action) {
      case 'added_to_community':
        return 'Added to Community';
      case 'new_message':
        return 'New Message';
      case 'new_member':
        return 'New Member Joined';
      default:
        return 'Community Update';
    }
  }

  static String _getCommunityNotificationBody(String action, String communityName, String? senderName, String? messagePreview) {
    switch (action) {
      case 'added_to_community':
        return 'You have been added to "$communityName" community';
      case 'new_message':
        return '${senderName ?? 'Someone'} sent a message in "$communityName"${messagePreview != null ? ': $messagePreview' : ''}';
      case 'new_member':
        return '${senderName ?? 'Someone'} joined "$communityName" community';
      default:
        return 'Update in "$communityName" community';
    }
  }

  static String _getDocumentNotificationTitle(String action) {
    switch (action) {
      case 'uploaded':
        return 'Document Uploaded for Review';
      case 'approved':
        return 'Document Approved';
      case 'rejected':
        return 'Document Rejected';
      default:
        return 'Document Update';
    }
  }

  static String _getDocumentNotificationBody(String action, String documentName, String? professorName, String? rejectionReason) {
    switch (action) {
      case 'uploaded':
        return 'Document "$documentName" has been uploaded and is pending approval';
      case 'approved':
        return 'Your document "$documentName" has been approved by ${professorName ?? 'professor'}';
      case 'rejected':
        return 'Your document "$documentName" was rejected${rejectionReason != null ? ': $rejectionReason' : ''}';
      default:
        return 'Update on document "$documentName"';
    }
  }
}