import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/screens/chat.dart';
import 'package:flutter_chat/widgets/user_image.dart';

final _firebaseAuth = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  var _isLogin = true;
  var _username = '';
  var _emailId = '';
  var _password = '';
  File? _userImageFile;
  var isAuthontication = false;

  void _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid || _userImageFile == null && !_isLogin) {
      return;
    }

    _formKey.currentState!.save();
    try {
      setState(() {
        isAuthontication = true;
      });
      if (_isLogin) {
        await _firebaseAuth.signInWithEmailAndPassword(
          email: _emailId,
          password: _password,
        );
        goToChatScreen();
      } else {
        final userCredential =
            await _firebaseAuth.createUserWithEmailAndPassword(
          email: _emailId,
          password: _password,
        );
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child('${userCredential.user!.uid}.jpg');
        await storageRef.putFile(_userImageFile!);
        final imageFile = await storageRef.getDownloadURL();
        print(imageFile);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _username,
          'email': _emailId,
          'image_url': imageFile,
        });

        _showSnakbarMessgae(
            'User created successfully.${userCredential.user!.email}');
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        _showSnakbarMessgae('The account already exists for that email.');
      } else if (error.code == 'network-request-failed') {
        _showSnakbarMessgae('Network error. Please check your connection.');
      } else {
        _showSnakbarMessgae(error.message ??
            'An error occurred. Please check your credentials.');
      }
      setState(() {
        isAuthontication = false;
      });
    }
  }

  void goToChatScreen() {
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => ChatScreen(),
    ));
  }

  void _showSnakbarMessgae(String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(
                bottom: 20,
                top: 30,
                left: 20,
                right: 20,
              ),
              width: 200,
              child: Image.asset('assets/images/chat.png'),
            ),
            Card(
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLogin)
                        UserImagePicker(
                          onPickedImage: (pickedImage) =>
                              _userImageFile = pickedImage,
                        ),
                      if (!_isLogin)
                        TextFormField(
                          key: ValueKey('username'),
                          enableSuggestions: false,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(labelText: 'Username'),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length < 4) {
                              return 'Please must be at least 7 characters long.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _username = value!;
                          },
                        ),
                      TextFormField(
                        key: ValueKey('email'),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(labelText: 'Email Address'),
                        validator: (value) {
                          if (value!.isEmpty || !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _emailId = value!;
                        },
                      ),
                      TextFormField(
                        key: ValueKey('password'),
                        obscureText: true,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(labelText: 'Password'),
                        validator: (value) {
                          if (value!.isEmpty || value.length < 7) {
                            return 'Password must be at least 7 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value!;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (isAuthontication) const CircularProgressIndicator(),
                      if (!isAuthontication)
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          child: Text(_isLogin ? 'Login' : 'Signup'),
                        ),
                      if (!isAuthontication)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(_isLogin
                              ? 'Create new account'
                              : 'I already have an account. Login.'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
