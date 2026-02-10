import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/notifications/data/models/notifications_model.dart';
import 'package:get/get.dart';

class NotificationsFirebaseDataSource {
  final fs = Get.find<FirebaseServices>();

  Stream<List<NotificationsModel>> getNotifications() {
    return fs.firestore
        .collection("notifications")
        .where("receiverId", isEqualTo: fs.currentUser!.uid)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationsModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Future<void> markNotificationAsRead({required String notificationId}) async {
    await fs.firestore.collection("notifications").doc(notificationId).update({
      "isRead": true,
    });
  }

  Future<void> markAllNotificationsAsRead() async {
    await fs.firestore
        .collection("notifications")
        .where("receiverId", isEqualTo: fs.currentUser!.uid)
        .where("isRead", isEqualTo: false)
        .get()
        .then((snapshot) {
          final batch = fs.firestore.batch();
          for (var doc in snapshot.docs) {
            batch.update(doc.reference, {"isRead": true});
          }
          batch.commit();
        });
  }

  Stream<int> getUnreadCountStream() {
    return fs.firestore
        .collection("notifications")
        .where("receiverId", isEqualTo: fs.currentUser!.uid)
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> deleteNotification({required String notificationId}) async {
    await fs.firestore.collection("notifications").doc(notificationId).delete();
  }

  Future<void> deleteAllNotifications() async {
    await fs.firestore
        .collection("notifications")
        .where("receiverId", isEqualTo: fs.currentUser!.uid)
        .get()
        .then((snapshot) {
          final batch = fs.firestore.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          batch.commit();
        });
  }
}
