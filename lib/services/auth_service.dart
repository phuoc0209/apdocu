import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last active
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toMap());

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(displayName);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.message}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      // Only update specific fields, not the entire document
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'bio': user.bio,
        'phoneNumber': user.phoneNumber,
      });
      
      // Also update display name in Firebase Auth
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(user.displayName);
        if (user.photoURL != null) {
          await _auth.currentUser!.updatePhotoURL(user.photoURL);
        }
      }
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  // Follow/Unfollow user
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      await _firestore.runTransaction((transaction) async {
        final currentUserDoc = await transaction.get(currentUserRef);
        final targetUserDoc = await transaction.get(targetUserRef);

        if (!currentUserDoc.exists || !targetUserDoc.exists) {
          throw Exception('User not found');
        }

        final currentUser = UserModel.fromDocument(currentUserDoc);
        final targetUser = UserModel.fromDocument(targetUserDoc);

        List<String> currentUserFollowing = List.from(currentUser.following);
        List<String> targetUserFollowers = List.from(targetUser.followers);

        if (currentUserFollowing.contains(targetUserId)) {
          // Unfollow
          currentUserFollowing.remove(targetUserId);
          targetUserFollowers.remove(currentUserId);
        } else {
          // Follow
          currentUserFollowing.add(targetUserId);
          targetUserFollowers.add(currentUserId);
        }

        transaction.update(currentUserRef, {'following': currentUserFollowing});
        transaction.update(targetUserRef, {'followers': targetUserFollowers});
      });
    } catch (e) {
      print('Toggle follow error: $e');
      rethrow;
    }
  }

  // Check if following
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        final user = UserModel.fromDocument(doc);
        return user.following.contains(targetUserId);
      }
      return false;
    } catch (e) {
      print('Check following error: $e');
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }
}
