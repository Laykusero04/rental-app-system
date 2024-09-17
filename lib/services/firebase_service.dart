import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred during sign in';
    }
  }

  Future<int> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc['role'] as int;
    } catch (e) {
      throw 'Error fetching user role';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  Future<void> addHouseType(String type) async {
    try {
      await _firestore.collection('houseTypes').add({
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to add house type: $e';
    }
  }

  Stream<QuerySnapshot> getHouseTypes() {
    return _firestore.collection('houseTypes').orderBy('type').snapshots();
  }

  Future<void> updateHouseType(String id, String newType) async {
    try {
      await _firestore.collection('houseTypes').doc(id).update({
        'type': newType,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update house type: $e';
    }
  }

  Future<void> deleteHouseType(String id) async {
    try {
      await _firestore.collection('houseTypes').doc(id).delete();
    } catch (e) {
      throw 'Failed to delete house type: $e';
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child('house_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  Future<void> addHouse(Map<String, dynamic> houseData, File? imageFile) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        houseData['createdBy'] = currentUser.uid;
        houseData['createdAt'] = FieldValue.serverTimestamp();

        if (imageFile != null) {
          String imageUrl = await uploadImage(imageFile);
          houseData['imageUrl'] = imageUrl;
        }

        await _firestore.collection('houses').add(houseData);
      } else {
        throw 'No user logged in';
      }
    } catch (e) {
      throw 'Failed to add house: $e';
    }
  }

  Future<void> updateHouse(
      String id, Map<String, dynamic> houseData, File? imageFile) async {
    try {
      if (imageFile != null) {
        String imageUrl = await uploadImage(imageFile);
        houseData['imageUrl'] = imageUrl;
      }
      await _firestore.collection('houses').doc(id).update(houseData);
    } catch (e) {
      throw 'Failed to update house: $e';
    }
  }

  Stream<QuerySnapshot> getHouses() {
    return _firestore
        .collection('houses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteHouse(String id) async {
    try {
      await _firestore.collection('houses').doc(id).delete();
    } catch (e) {
      throw 'Failed to delete house: $e';
    }
  }

  Stream<QuerySnapshot> getHousesForCurrentUser() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      return _firestore
          .collection('houses')
          .where('createdBy', isEqualTo: userId)
          .snapshots();
    } else {
      // Return an empty stream if there's no current user
      return Stream.empty();
    }
  }

  Future<void> createUser(String email, String password, String firstName,
      String lastName, int role) async {
    try {
      // Create the user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      });
    } catch (e) {
      throw 'Failed to create user: $e';
    }
  }

  Future<Map<String, dynamic>> getUser(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      throw 'Failed to get user: $e';
    }
  }

  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).update(userData);
    } catch (e) {
      throw 'Failed to update user: $e';
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      // Delete user from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user from Firebase Auth
      User? user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      } else {
        throw 'Cannot delete user: Current user mismatch';
      }
    } catch (e) {
      throw 'Failed to delete user: $e';
    }
  }

  Future<void> createUserWithAuth(String email, String password,
      String firstName, String lastName, int role) async {
    try {
      // Create the user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'The account already exists for that email.';
      } else {
        throw 'Error: ${e.message}';
      }
    } catch (e) {
      throw 'Failed to create user: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentsForMonth(
      String month, String year,
      {required bool isAdmin}) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw 'No user logged in';
    }

    int monthNumber = DateFormat('MMMM').parse(month).month;
    DateTime startDate = DateTime(int.parse(year), monthNumber, 1);
    DateTime endDate = DateTime(int.parse(year), monthNumber + 1, 0);

    QuerySnapshot housesSnapshot;
    if (isAdmin) {
      housesSnapshot = await _firestore.collection('houses').get();
    } else {
      housesSnapshot = await _firestore
          .collection('houses')
          .where('createdBy', isEqualTo: currentUser.uid)
          .get();
    }

    List<Map<String, dynamic>> allPayments = [];

    for (var houseDoc in housesSnapshot.docs) {
      QuerySnapshot paymentsSnapshot = await houseDoc.reference
          .collection('payments')
          .where('paymentDate', isGreaterThanOrEqualTo: startDate)
          .where('paymentDate', isLessThanOrEqualTo: endDate)
          .get();

      for (var paymentDoc in paymentsSnapshot.docs) {
        Map<String, dynamic> paymentData =
            paymentDoc.data() as Map<String, dynamic>;
        paymentData['houseNumber'] = houseDoc['houseNumber'];
        paymentData['tenantName'] =
            await _getTenantName(paymentData['tenantId']);
        allPayments.add(paymentData);
      }
    }

    allPayments.sort((a, b) => (b['paymentDate'] as Timestamp)
        .compareTo(a['paymentDate'] as Timestamp));

    return allPayments;
  }

  Future<String> _getTenantName(String tenantId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(tenantId).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    return '${userData['first_name']} ${userData['last_name']}';
  }

  Stream<QuerySnapshot> getAccessRequests(String houseId) {
    return _firestore
        .collection('accessRequests')
        .where('houseId', isEqualTo: houseId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<QuerySnapshot> getHousesWithBalance() async {
    QuerySnapshot housesSnapshot = await _firestore
        .collection('houses')
        .where('currentBalance', isGreaterThan: 0)
        .get();

    for (var houseDoc in housesSnapshot.docs) {
      var houseData = houseDoc.data() as Map<String, dynamic>;
      var userData = await getUser(houseData['tenantId']);
      houseDoc.reference.update({
        'tenantName': '${userData['first_name']} ${userData['last_name']}',
      });
    }

    return housesSnapshot;
  }

  int _getMonthNumber(String month) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months.indexOf(month) + 1;
  }
}
