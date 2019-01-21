import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

var currentUserEmail;

class ChatMessageListItem extends StatelessWidget {
  final DataSnapshot messageSnapshot;
  final Animation animation;

  ChatMessageListItem({this.messageSnapshot, this.animation});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.decelerate),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: currentUserEmail == messageSnapshot.value['email']
              ? getSentMessageLayout()
              : getReceivedMessageLayout(),
        ),
      ),
    );
  }

  List<Widget> getSentMessageLayout() {
    return <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundImage:
                    NetworkImage(messageSnapshot.value['senderPhotoUrl']),
              ),
            )
          ],
        ),
      )
    ];
  }

  List<Widget> getReceivedMessageLayout() {
    return <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundImage:
                  NetworkImage(messageSnapshot.value['senderPhotoUrl']),
            ),
          )
        ],
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              messageSnapshot.value['sendName'],
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.black26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: messageSnapshot.value['imageUrl'] != null
                  ? Image.network(
                      messageSnapshot.value['imageUrl'],
                      width: 250.0,
                    )
                  : Text(
                      messageSnapshot.value['text'],
                    ),
            ),
          ],
        ),
      )
    ];
  }
}
