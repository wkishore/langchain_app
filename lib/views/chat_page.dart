import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:langchain_app/components/chat_bubble.dart';
import 'package:langchain_app/components/my_text_field.dart';
import 'package:langchain_app/config/config.dart';
import 'package:langchain_app/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:langchain_app/services/langchain/langchain_services_implementation.dart';
import 'package:langchain_app/services/notifiers/query_notifier.dart';



class ChatPage extends ConsumerStatefulWidget {
  final String conversationName;
  final String conversationId;
  final CameraDescription firstCamera;
  final ImageLabeler imageLabeler;
  const ChatPage({super.key, required this.conversationId, required this.conversationName, required this.firstCamera, required this.imageLabeler});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void sendMessage() async{
    if(controller.text.isNotEmpty){
      String msg = controller.text;
      controller.clear();
      await _chatService.sendMessage(widget.conversationId, msg, true);
      String ans = await ref.read(langchainServiceProvider).queryPineConeVectorStore(ServiceConfig.indexName, controller.text);
      sendLLMReply(ans);
    }
  }
  
  void sendLLMReply(String msg) async{
    await _chatService.sendMessage(widget.conversationId, msg, false);
  }
  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(queryNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.conversationName),),
      body: Column(
        children: [
          Expanded(child: _buildMsgList()),
          _buildMsgInput(context , queryState),
        ],
      ),
    );
  }

  Widget _buildMsgList(){
    return StreamBuilder(
      stream: _chatService.getMessages(_firebaseAuth.currentUser!.uid, widget.conversationId), 
      builder: (context, snapshot){
        if(snapshot.hasError){
          return Text('${snapshot.error}');
        }
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Text('Loading..');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No old found'));
        }
        return ListView(
          children: snapshot.data!.docs.map((document)=>_buildMsgItem(document)).toList(),
        );
      }
    );
  }

  Widget _buildMsgItem(DocumentSnapshot document){
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)? Alignment.centerRight:Alignment.centerLeft;
    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)? CrossAxisAlignment.end:CrossAxisAlignment.start,
        children: [
          Text(data['senderEmail']),
          ChatBubble(message: data['message']),
        ],
      ),
    );
  }

  Widget _buildMsgInput(BuildContext context, QueryState queryState){
    return Row(children: [
      IconButton(
        onPressed: () async {
          
          String ans = await ref.read(langchainServiceProvider).onImageClick(context,
            widget.firstCamera, 
            widget.imageLabeler);
          
          sendLLMReply(ans);
        },
        icon: const Icon(Icons.camera)),
      Expanded(child: MyTextField(controller: controller, hintText: 'Enter Message', obscureText: false)),
      IconButton(onPressed: sendMessage, icon: const Icon(Icons.send))
    ],);
  }
}