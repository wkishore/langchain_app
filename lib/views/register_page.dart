// ignore_for_file: unnecessary_import

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:langchain_app/components/my_button.dart';
import 'package:langchain_app/components/my_text_field.dart';
import 'package:langchain_app/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class RegisterPage extends ConsumerStatefulWidget{
  final void Function()? onTap;
  const RegisterPage({super.key, this.onTap});

  @override
  RegisterPageState createState()=> RegisterPageState();
}

class RegisterPageState extends ConsumerState<RegisterPage>{
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor:Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50,),
                const Icon(
                  Icons.message,
                  size: 100
                ),
                const SizedBox(height: 50,),
                const Text(
                  "Register Page",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25,),
                MyTextField(controller: emailController, hintText: 'Email', obscureText: false),
                const SizedBox(height: 25,),
                MyTextField(controller: passwordController, hintText: 'Password', obscureText: true),
                const SizedBox(height: 25,),
                MyTextField(controller:confirmPasswordController, hintText: 'Confirm Password', obscureText: true),
                const SizedBox(height: 25,),
                MyButton(onTap: signUp, text: "Sign Up"),
                const SizedBox(height: 25,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Registed?"),
                    const SizedBox(width: 4,),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void signUp () async {
    if(passwordController.text != confirmPasswordController.text){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords dont match")));
      return;
    }
    //final authService = Provider.of<AuthService>(context, listen: false);
    try {
      ref.read(authServiceProvider).createUser(emailController.text, passwordController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}