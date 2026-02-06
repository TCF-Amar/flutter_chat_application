
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseServices extends GetxService {
  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;
  late final FirebaseDatabase database;
  late final FirebaseMessaging messaging;

  //? Initialize firebase services
  @override
  void onInit() {
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    database = FirebaseDatabase.instance;
    messaging = FirebaseMessaging.instance;
    super.onInit();
  }

  //? Current firebase user
  User? get currentUser => auth.currentUser;

  //? Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  //? Get current user ID
  String? get currentUserId => currentUser?.uid;

  //? Get current user email
  String? get currentUserEmail => currentUser?.email;

 
}
