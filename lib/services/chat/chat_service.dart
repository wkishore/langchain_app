import 'package:langchain_app/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_string/random_string.dart';

class ChatService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  Future<void> sendMessage(String chatRoomId,String message, bool isUser) async{
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp ts = Timestamp.now();
    Message newMsg;

    if(isUser){
      newMsg = Message(senderEmail: currentUserEmail, senderId: currentUserId, recieverId: 'Gemini', message: message, ts: ts);
    }
    else{
      newMsg = Message(senderEmail: currentUserEmail, senderId: 'Gemini', recieverId: currentUserId, message: message, ts: ts);
    }
    await _fireStore.collection('users').doc(currentUserId).collection('chat_rooms').doc(chatRoomId).collection('messages').add(newMsg.toMap());

  }

  void createChat(String conversationName) async{
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    String randomChatId = randomAlphaNumeric(28);
    List<String> ids = [currentUserId, randomChatId];
    String chatRoomId = ids.join("_");
    await _fireStore.collection('users').doc(currentUserId).collection('chat_rooms').doc(chatRoomId).set({
    'name': conversationName,  
    'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessages(String currentUserId,String chatRoomId){
    return _fireStore.collection('users').doc(currentUserId).collection('chat_rooms').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: false).snapshots();
  }
}