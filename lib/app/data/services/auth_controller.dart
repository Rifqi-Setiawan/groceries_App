import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:tubes_motion/app/routes/app_pages.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Tambahkan ini

  Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    // Tambahkan username
    await _ensureFirebaseInitialized();

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      // Tambahkan username
      Get.snackbar("Error", "Email, password, dan username harus diisi!");
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser.value = userCredential.user;
      update();

      // Simpan data pengguna ke Firestore
      await _saveUserDataToFirestore(userCredential.user!.uid, email, username,
          password); // Tambahkan password

      Get.offAllNamed(Routes.LOGIN);
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.code);
    } catch (e) {
      Get.snackbar("Error", "Gagal mendaftar: ${e.toString()}");
    }
  }

  // Fungsi untuk menyimpan data pengguna ke Firestore
  Future<void> _saveUserDataToFirestore(
      String uid, String email, String username, String password) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'password': password, // Tambahkan password
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc('initialCart')
          .set({});
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc('initialOrder')
          .set({});
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data pengguna: ${e.toString()}");
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    await _ensureFirebaseInitialized();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Email dan password harus diisi!");
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser.value = userCredential.user;
      update();

      Get.offAllNamed(Routes.DASHBOARD);
    } on FirebaseAuthException catch (e) {
      String message = "Gagal login.";
      if (e.code == 'user-not-found') {
        message = "Email tidak ditemukan!";
      } else if (e.code == 'wrong-password') {
        message = "Password salah!";
      }
      Get.snackbar("Error", message);
    } catch (e) {
      Get.snackbar("Error", "Gagal login: ${e.toString()}");
    }
  }

  // Logout
  Future<void> logout() async {
    if (firebaseUser.value == null) {
      Get.snackbar("Error", "Tidak ada pengguna yang sedang login.");
      return;
    }

    await _auth.signOut();
    firebaseUser.value = null;
    update();
    Get.offAllNamed(Routes.LOGIN);
  }
}
