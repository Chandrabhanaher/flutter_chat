import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chat').snapshots(),
        builder: (ctx, chatSnapshots) {
          if (chatSnapshots.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (chatSnapshots.data == null || chatSnapshots.data!.docs.isEmpty) {
            return Center(
              child: Text('No messages found'),
            );
          }
          if (chatSnapshots.hasError) {
            return Center(
              child: Text('Something went wrong...'),
            );
          }
          final chatDocs = chatSnapshots.data!.docs;
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (ctx, index) => Text(chatDocs[index]['text']),
          );
        });
  }
}
