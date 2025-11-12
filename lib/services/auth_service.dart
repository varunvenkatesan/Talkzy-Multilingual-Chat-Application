import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // This import is likely not needed in a Service class
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // FIX: Standard Dart convention is lowercase for property/getter names
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null) {
        UserModel? existing;
        try {
          existing = await _firestoreService.getUser(user.uid);
        } catch (_) {
          existing = null;
        }

        if (existing == null) {
          final created = UserModel(
            id: user.uid,
            email: user.email ?? email,
            displayName: (user.displayName != null && user.displayName!.isNotEmpty)
                ? user.displayName!
                : (email.contains('@') ? email.split('@').first : email),
            photoURL: user.photoURL ?? '',
            isOnline: true,
            lastSeen: DateTime.now(),
            createdAt: DateTime.now(),
          );
          try {
            await _firestoreService.createUser(created);
          } catch (_) {}
          return created;
        } else {
          try {
            await _firestoreService.updateUserOnlineStatus(user.uid, true);
          } catch (_) {}
          return existing;
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Re-throw the FirebaseAuthException to allow for specific error handling (e.g., wrong password)
      throw Exception('Failed To Sign In: ${e.code}');
    } catch (e) {
      throw Exception('Failed To Sign In: ${e.toString()}');
    }
  }

  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    String gender, {
    String? avatarCode,
  }) async {
    try {
      print('🚀 Starting registration for: $email');
      
      // Step 1: Create Firebase Auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      
      if (user != null) {
        print('✅ Firebase Auth user created: ${user.uid}');
        
        // Step 2: Update display name
        try {
          await user.updateDisplayName(displayName);
          print('✅ Display name updated');
        } catch (e) {
          print('⚠️ Could not update display name: $e');
        }

        // Step 3: Create user model
        final userModel = UserModel(
          id: user.uid,
          email: email,
          displayName: displayName,
          photoURL: '',
          gender: gender,
          avatarCode: avatarCode,
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime.now(),
        );
        print('✅ User model created');

        // Step 4: Create Firestore document
        print('📝 Creating Firestore document...');
        try {
          await _firestoreService.createUser(userModel);
          print('✅ Firestore document created successfully');
        } catch (e) {
          print('⚠️ Skipping Firestore user creation due to error: $e');
        }
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('Failed To Register: ${e.code}');
    } catch (e) {
      print('❌ Registration Error: ${e.toString()}');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Failed To Register: ${e.toString()}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // The extra parentheses around email are unnecessary
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed To Send Password Reset Email: ${e.code}');
    } catch (e) {
      throw Exception('Failed To Send Password Reset Email: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      print('🚪 Starting sign out process...');
      
      // Try to update online status, but don't fail if it errors
      if (currentUser != null && currentUserId != null) {
        try {
          print('📝 Updating user online status to offline...');
          await _firestoreService.updateUserOnlineStatus(currentUserId!, false)
              .timeout(const Duration(seconds: 5));
          print('✅ Online status updated');
        } catch (e) {
          // Log but don't throw - allow logout to continue even if Firestore fails
          print('⚠️ Warning: Could not update online status: ${e.toString()}');
          print('⚠️ Continuing with logout anyway...');
        }
      }

      print('🔓 Signing out from Firebase Auth...');
      await _auth.signOut();
      print('✅ Sign out successful');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error during sign out: ${e.code}');
      throw Exception('Failed to Sign Out: ${e.code}');
    } catch (e) {
      print('❌ Sign out error: ${e.toString()}');
      throw Exception('Failed to Sign Out: ${e.toString()}');
    }
  }

  Future<void> reauthenticate(String email, String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception('Re-authentication failed: ${e.code}');
    } catch (e) {
      throw Exception('Re-authentication failed: ${e.toString()}');
    }
  }

  Future<void> deleteAccount({String? email, String? password}) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Re-authenticate if email/password provided
        if (email != null && password != null) {
          await reauthenticate(email, password);
        }
        await _firestoreService.deleteUser(user.uid);
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'Failed to Delete: ${e.code}. Please re-authenticate and try again.');
      }
      throw Exception('Failed to Delete: ${e.code}');
    } catch (e) {
      throw Exception('Failed to Delete: ${e.toString()}');
    }
  }
}
