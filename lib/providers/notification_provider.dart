import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<NotificationModel> _notifications = [];
  StreamSubscription? _subscription;

  List<NotificationModel> get notifications => [..._notifications];
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String? _currentUserId;

  void setUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    _subscription?.cancel();
    if (userId != null) {
      _subscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('date', descending: true)
          .snapshots()
          .listen((snapshot) {
        _notifications = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      });
    } else {
      _notifications = [];
      notifyListeners();
    }
  }

  Future<void> pushNotification(String title, String body) async {
    if (_currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'date': Timestamp.now(),
      'isRead': false,
    });
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
