import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_app/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;
  bool isRegister = true;
  bool _obscureText = true;

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUseerWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _title() {
    return const Text('Login/Register Page');
  }

  Widget _entryField(
    String title,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: title,
      ),
    );
  }

  Widget _passwordField(
    String title,
    TextEditingController _controllerPassword,
  ) {
    return TextField(
      controller: _controllerPassword,
      obscureText:
          _obscureText, // Set this to true to show dots for password-like text
      decoration: InputDecoration(
        labelText: title,
        suffixIcon: IconButton(
          onPressed: _toggleObscureText,
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }

  Widget _errorMessage() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(
        errorMessage ?? '',
        style: TextStyle(
          color: Colors.red, // Set the text color to red for error messages
        ),
      ),
    );
  }

  Widget _loginButton() {
    return ElevatedButton(
      onPressed: isLogin ? signInWithEmailAndPassword : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Colors.purple, // Set the button's background color to purple
      ),
      child: Text(
        'Login',
        style: TextStyle(color: Colors.white), // Set text color to white
      ),
    );
  }

  Widget _registerButton() {
    return ElevatedButton(
      onPressed: isRegister ? createUseerWithEmailAndPassword : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Colors.purple, // Set the button's background color to purple
      ),
      child: Text(
        'Register',
        style: TextStyle(color: Colors.white), // Set text color to white
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set the app's primary and accent color to purple
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.purple,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: _title(),
          backgroundColor: Colors.purple,
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _entryField('email', _controllerEmail),
              _passwordField('password', _controllerPassword),
              _errorMessage(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _loginButton(),
                  SizedBox(width: 16), // Add spacing between buttons
                  _registerButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
