import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AuthService extends ChangeNotifier{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  Future<UserCredential> signIn(String email, String password) async {
    try{
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      _fireStore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge:true));
      return userCredential;
    }
    on FirebaseAuthException catch(e){
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async{
    _firebaseAuth.signOut();
  }

  Future<UserCredential> createUser(String email , String password) async {
    try{
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      _fireStore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge:true));
      return userCredential;
    } on FirebaseAuthException catch (e){
      throw Exception(e.toString());
    }
  }
}

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) => AuthService());