import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String senderId;
  String senderEmail;
  String recieverId;
  String message;
  Timestamp ts;

  Message({required this.senderEmail, required this.senderId, required this.recieverId, required this.message, required this.ts});
  
  Map<String, dynamic> toMap(){
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'recieverId': recieverId,
      'message': message,
      'timestamp': ts,
    };
  }
}