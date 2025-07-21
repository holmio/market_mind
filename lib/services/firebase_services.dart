import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class FirebaseServices {
  // Singleton pattern
  static FirebaseServices? _instance;
  static FirebaseServices get instance => _instance ??= FirebaseServices._();
  FirebaseServices._();

  // Service instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  // ============================================================================
  // AUTHENTICATION FUNCTIONS
  // ============================================================================

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  /// Create account with email and password
  Future<UserCredential?> createAccountWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Create account error: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }

  // ============================================================================
  // FIRESTORE DATABASE FUNCTIONS
  // ============================================================================

  /// Add document to collection
  Future<DocumentReference?> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      DocumentReference ref = await _firestore.collection(collection).add(data);
      return ref;
    } catch (e) {
      print('Add document error: $e');
      return null;
    }
  }

  /// Get document by ID
  Future<DocumentSnapshot?> getDocument(String collection, String documentId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(documentId).get();
      return doc;
    } catch (e) {
      print('Get document error: $e');
      return null;
    }
  }

  /// Update document
  Future<bool> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
      return true;
    } catch (e) {
      print('Update document error: $e');
      return false;
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
      return true;
    } catch (e) {
      print('Delete document error: $e');
      return false;
    }
  }

  /// Get collection stream
  Stream<QuerySnapshot> getCollectionStream(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  /// Get documents with query
  Future<QuerySnapshot?> getDocumentsWithQuery(
    String collection, {
    String? field,
    dynamic isEqualTo,
    dynamic isGreaterThan,
    dynamic isLessThan,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (field != null && isEqualTo != null) {
        query = query.where(field, isEqualTo: isEqualTo);
      }
      if (field != null && isGreaterThan != null) {
        query = query.where(field, isGreaterThan: isGreaterThan);
      }
      if (field != null && isLessThan != null) {
        query = query.where(field, isLessThan: isLessThan);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot;
    } catch (e) {
      print('Query documents error: $e');
      return null;
    }
  }

  // ============================================================================
  // STORAGE FUNCTIONS
  // ============================================================================

  /// Upload file to Firebase Storage
  Future<String?> uploadFile(File file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload file error: $e');
      return null;
    }
  }

  /// Delete file from Firebase Storage
  Future<bool> deleteFile(String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      await ref.delete();
      return true;
    } catch (e) {
      print('Delete file error: $e');
      return false;
    }
  }

  // ============================================================================
  // CLOUD FUNCTIONS
  // ============================================================================

  /// Call a callable Firebase Function
  Future<dynamic> callFunction(String functionName, {Map<String, dynamic>? data}) async {
    try {
      HttpsCallable callable = _functions.httpsCallable(functionName);
      HttpsCallableResult result = await callable.call(data);
      return result.data;
    } catch (e) {
      print('Call function error: $e');
      return null;
    }
  }

  // Example: Call a function to send a custom email
  Future<bool> sendCustomEmail(String to, String subject, String body) async {
    try {
      await callFunction('sendEmail', data: {
        'to': to,
        'subject': subject,
        'body': body,
      });
      return true;
    } catch (e) {
      print('Send email error: $e');
      return false;
    }
  }

  // ============================================================================
  // MESSAGING (PUSH NOTIFICATIONS)
  // ============================================================================

  /// Initialize messaging and get FCM token
  Future<String?> initializeMessaging() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await _messaging.getToken();
        print('FCM Token: $token');
        
        // Save token to user document (optional)
        if (currentUser != null && token != null) {
          await updateDocument('users', currentUser!.uid, {'fcmToken': token});
        }
        
        return token;
      }
      return null;
    } catch (e) {
      print('Initialize messaging error: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Subscribe to topic error: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Unsubscribe from topic error: $e');
    }
  }

  // ============================================================================
  // USER PROFILE FUNCTIONS
  // ============================================================================

  /// Create or update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (currentUser == null) return false;

      // Update Firebase Auth profile
      if (displayName != null) {
        await currentUser!.updateDisplayName(displayName);
      }

      // Update user document in Firestore
      Map<String, dynamic> userData = {
        'uid': currentUser!.uid,
        'email': currentUser!.email,
        'displayName': displayName ?? currentUser!.displayName,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (phoneNumber != null) userData['phoneNumber'] = phoneNumber;
      if (additionalData != null) userData.addAll(additionalData);

      await _firestore.collection('users').doc(currentUser!.uid).set(userData, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Update user profile error: $e');
      return false;
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    try {
      String uid = userId ?? currentUser?.uid ?? '';
      if (uid.isEmpty) return null;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }

  // ============================================================================
  // ANALYTICS HELPER
  // ============================================================================

  /// Log custom event (you'll need to import firebase_analytics)
  // Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
  //   try {
  //     await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  //   } catch (e) {
  //     print('Log event error: $e');
  //   }
  // }
}
