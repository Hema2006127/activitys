import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream لحالة المستخدم
  static Stream<User?> get userStream => _auth.authStateChanges();

  // المستخدم الحالي
  static User? get currentUser => _auth.currentUser;

  // ======== Email / Password ========

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(displayName.trim());
    return cred;
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ======== Google Sign-In ========

  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
    if (gUser == null) return null; // المستخدم ألغى

    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // ======== تسجيل الخروج ========

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ======== رسائل الخطأ بالعربي ========

  static String getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'لا يوجد حساب بهذا البريد الإلكتروني';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة';
        case 'invalid-credential':
          return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        case 'email-already-in-use':
          return 'هذا البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
        case 'invalid-email':
          return 'صيغة البريد الإلكتروني غير صحيحة';
        case 'too-many-requests':
          return 'محاولات كثيرة، حاول لاحقاً';
        case 'network-request-failed':
          return 'تحقق من اتصالك بالإنترنت';
        default:
          return e.message ?? 'حدث خطأ، حاول مجدداً';
      }
    }
    return 'حدث خطأ، حاول مجدداً';
  }
}
