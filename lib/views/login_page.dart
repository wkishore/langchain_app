import 'package:langchain_app/components/my_button.dart';
import 'package:langchain_app/components/my_text_field.dart';
import 'package:langchain_app/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget{
  final void Function()? onTap;
  const LoginPage({super.key, this.onTap});

  @override
  LoginPageState createState()=> LoginPageState();
}

class LoginPageState extends ConsumerState<LoginPage>{
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signIn() async {
    // final authService = Provider.of<AuthService>(context, listen: false);
    try {
      // await authService.signIn(emailController.text, passwordController.text);
      ref.read(authServiceProvider).signIn(emailController.text, passwordController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
  
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
                  "Login Page",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25,),
                MyTextField(controller: emailController, hintText: 'Email', obscureText: false),
                const SizedBox(height: 25,),
                MyTextField(controller: passwordController, hintText: 'Password', obscureText: true),
                const SizedBox(height: 25,),
                MyButton(onTap: signIn, text: "Sign In"),
                const SizedBox(height: 25,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Not registed?"),
                    const SizedBox(width: 4,),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        "Register now",
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
}