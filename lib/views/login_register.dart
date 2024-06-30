import 'package:langchain_app/views/login_page.dart';
import 'package:langchain_app/views/register_page.dart';
import 'package:flutter/material.dart';

class LoginRegister extends StatefulWidget{
  const LoginRegister({super.key});
  @override
  State<LoginRegister> createState()=> _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister>{

  bool showLogin = true;

  void togglePages(){
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context){
    if(showLogin){
      return LoginPage(onTap: togglePages);
    }
    else {
      return RegisterPage(onTap: togglePages);
    }
  }
}