
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:langchain_app/services/auth/auth_service.dart';
import 'package:langchain_app/services/chat/chat_service.dart';
import 'package:langchain_app/views/chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';


class HomePage extends ConsumerStatefulWidget{
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState()=> _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late TextEditingController controller;
  final ChatService _chatService = ChatService();
  late CameraDescription firstCamera;
  late ImageLabeler imageLabeler;

  Future<String> getModelPath(String asset) async {
    final modelPath = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(path.dirname(modelPath)).create(recursive: true);
    final file = File(modelPath);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  void getStuffReady() async{
    controller = TextEditingController();
    await dotenv.load(fileName: '.env');
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    firstCamera = cameras.first;
    final modelPath = await getModelPath('assets/ml/detection.tflite');
    double confidenceThreshold=0.05;
    final options = LocalLabelerOptions(
      confidenceThreshold: confidenceThreshold,
      modelPath: modelPath,
    );
    imageLabeler = ImageLabeler(options: options);
  }
  @override
  Widget build(BuildContext context) {
    getStuffReady();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(icon: const Icon(Icons.add),
            onPressed: () async{
              final name = await openDialog();
              controller.clear();
              _chatService.createChat(name.toString());
            },
          ),
          IconButton(onPressed: signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _buildUserList(),
    );
  }

  Future<String?> openDialog()=> showDialog<String>(
    context: context,
    builder: (context)=>AlertDialog(
      title: const Text('New Conversation'),
      content: TextField(
        decoration: const InputDecoration(
          hintText: 'Conversation Name(Required)',
        ),
        controller: controller,
      ),
      actions: [
        TextButton(
          onPressed: (){
            if(controller.text.isNotEmpty){
              submit();
            }
            else{
              
            }
          },
          child: const Text('Submit'),
        )
      ],
    ),
  );

  void submit(){
    Navigator.of(context).pop(controller.text);
  }

  void signOut() {
    //final authService = Provider.of<AuthService>(context, listen: false);
    ref.read(authServiceProvider).signOut();
  }

  Widget _buildUserList(){
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').doc(_firebaseAuth.currentUser!.uid).collection('chat_rooms').snapshots(), 
      builder:(context,snapshot){
        if(snapshot.hasError){
          return const Text('Error');
        }
        if(snapshot.connectionState==ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No old found'));
        }
        return ListView(
          children: snapshot.data!.docs.map<Widget>((doc)=>_buildUserListItem(doc)).toList(),
        );
      }
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document){
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    return ListTile(
      title: Text(data['name']),
      tileColor: Colors.blue[600],
      textColor: Colors.white,
      onTap: (){
        Navigator.push(context, 
          MaterialPageRoute(builder: (context)=> ChatPage(
            conversationId: document.id,
            conversationName: data['name'],
            imageLabeler: imageLabeler,
            firstCamera: firstCamera,
           ),
          ),
        );
      },
    );
  }
}