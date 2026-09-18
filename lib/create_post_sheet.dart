import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});
  @override State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _textCtrl = TextEditingController();
  bool _posting = false;

  Future<void> _post() async {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(()=> _posting = true);
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'text': _textCtrl.text.trim(),
        'uid': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'userName': 'Oyo Corper',
        'state': 'Oyo',
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if(mounted) Navigator.pop(context);
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(()=> _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        TextField(controller: _textCtrl, maxLines: 5, autofocus: true, decoration: const InputDecoration(hintText: 'What is happening in your PPA? Share gist, news, market...', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: _posting ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)), onPressed: _post, child: const Text('Post to Feed'))),
        const SizedBox(height: 20),
      ]),
    );
  }
}
