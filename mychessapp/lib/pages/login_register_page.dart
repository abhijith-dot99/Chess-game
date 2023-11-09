import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginRegisterPageState createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String errorMessage = '';
  String _verificationId = '';
  bool isEmailLogin = true; // To track if the user selects email login
  bool showInputFields = false; // To control the visibility of input fields

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // Navigate to your home page if sign-in is successful
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // Navigate to your home page if registration is successful
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  void verifyPhoneNumber() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        // Navigate to the home page on automatic verification success
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          errorMessage = e.message ?? 'Verification failed';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          // Show a field to enter OTP
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  void signInWithOTP() async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otpController.text,
      );
      await _auth.signInWithCredential(credential);
      // Navigate to the home page on manual verification success
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Widget entryField(String title, TextEditingController controller, bool isPassword, {double bottomPadding = 10}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget submitButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }

  Widget loginMethodToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              isEmailLogin = true;
              showInputFields = true;
              _verificationId = ''; // Reset verification ID if switching back
            });
          },
          child: Text('Email Login'),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isEmailLogin = false;
              showInputFields = true;
            });
          },
          child: const Text('Phone Login'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hi, there"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Welcome',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              loginMethodToggle(),
              if (showInputFields) ...[
                const SizedBox(height: 20),
                if (isEmailLogin) ...[
                  entryField('Email', emailController, false),
                  entryField('Password', passwordController, true, bottomPadding: 0),
                  const SizedBox(height: 20),
                  submitButton('Sign In with Email', signInWithEmailAndPassword),
                  const SizedBox(height: 10),
                  submitButton('Register with Email', createUserWithEmailAndPassword),
                ] else ...[
                  entryField('Phone Number', phoneController, false, bottomPadding: 20),
                  if (_verificationId.isNotEmpty)
                    entryField('OTP', otpController, false, bottomPadding: 20),
                  if (_verificationId.isEmpty)
                    submitButton('Send OTP', verifyPhoneNumber),
                  if (_verificationId.isNotEmpty)
                    submitButton('Verify OTP', signInWithOTP),
                ],
              ],
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
