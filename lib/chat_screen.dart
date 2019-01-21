import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_chat_app/chat_message_list.dart';

final googleSignIn = GoogleSignIn();
final analytics = FirebaseAnalytics();
final auth = FirebaseAuth.instance;

var currentUserEmail;
var _scaffoldContext;

class ChatScreen extends StatefulWidget {
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  bool _isComposingMessage = false;
  final reference = FirebaseDatabase.instance.reference().child('message');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chat APP'),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        actions: <Widget>[
          Text(
            'Sign Out',
            style: TextStyle(
              color: Theme.of(context).platform == TargetPlatform.iOS
                  ? Colors.black26
                  : Theme.of(context).accentColor,
            ),
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _signout,
          )
        ],
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
              child: FirebaseAnimatedList(
                query: reference,
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                sort: (a, b) => b.key.compareTo(a.key),
                itemBuilder: (BuildContext context,
                        DataSnapshot messageSnapshot,
                        Animation<double> animation,
                        int index) =>
                    ChatMessageListItem(
                      messageSnapshot: messageSnapshot,
                      animation: animation,
                    ),
              ),
            ),
            Divider(
              height: 1.0,
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(
        color: _isComposingMessage
            ? Theme.of(context).accentColor
            : Theme.of(context).disabledColor,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.photo),
                color: Theme.of(context).accentColor,
                onPressed: () async {
                  await _ensureLoggedIn();

                  File imageFile =
                      await ImagePicker.pickImage(source: ImageSource.gallery);

                  int timeStamp = new DateTime.now().millisecondsSinceEpoch;

                  StorageReference storageReference = FirebaseStorage.instance
                      .ref()
                      .child('img_' + timeStamp.toString() + '.jpg');
                  StorageUploadTask uploadTask =
                      storageReference.putFile(imageFile);

                  Uri downloadUrl =
                      await uploadTask.lastSnapshot.ref.getDownloadURL();

                  _sendMessage(
                      messageText: null, imageUrl: downloadUrl.toString());
                },
              ),
            ),
            Flexible(
              child: TextField(
                controller: _textEditingController,
                onChanged: (String messageText) {
                  setState(() {
                    _isComposingMessage = messageText.length > 0;
                  });
                },
                onSubmitted: _textMessageSubmitted,
                decoration:
                    InputDecoration.collapsed(hintText: 'Send a message'),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? _getIOSSendButton()
                  : _getDefaultSendButton(),
            ),
          ],
        ),
      ),
    );
  }

  CupertinoButton _getIOSSendButton() {
    return CupertinoButton(
      child: Text('Send'),
      onPressed: _isComposingMessage
          ? () => _textMessageSubmitted(_textEditingController.text)
          : null,
    );
  }

  IconButton _getDefaultSendButton() {
    return IconButton(
      icon: Icon(Icons.send),
      onPressed: _isComposingMessage
          ? () => _textMessageSubmitted(_textEditingController.text)
          : null,
    );
  }

  Future _signout() async {
    await auth.signOut();
    googleSignIn.signOut();
    Scaffold.of(_scaffoldContext).showSnackBar(SnackBar(
      content: Text('User Logged Out'),
    ));
  }

  Future _ensureLoggedIn() async {
    GoogleSignInAccount signedInUser = googleSignIn.currentUser;

    if (signedInUser == null)
      signedInUser = await googleSignIn.signInSilently();

    if (signedInUser == null) {
      await googleSignIn.signIn();
      analytics.logLogin();
    }

    currentUserEmail = googleSignIn.currentUser.email;

    if (await auth.currentUser() == null) {
      GoogleSignInAuthentication credentials =
          await googleSignIn.currentUser.authentication;

      await auth.signInWithGoogle(
          idToken: credentials.idToken, accessToken: credentials.accessToken);
    }
  }

  void _sendMessage({String messageText, String imageUrl}) {
    reference.push().set({
      'text': messageText,
      'email': googleSignIn.currentUser.email,
      'imageUrl': imageUrl,
      'senderName': googleSignIn.currentUser.displayName,
      'senderPhotoUrl': googleSignIn.currentUser.photoUrl,
    });

    analytics.logEvent(name: 'send_message');
  }

  Future _textMessageSubmitted(String text) async {
    _textEditingController.clear();

    setState(() {
      _isComposingMessage = false;
    });
    await _ensureLoggedIn();

    _sendMessage(messageText: text, imageUrl: null);
  }
}
