import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});
  @override State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _textCtrl = TextEditingController();
  bool _posting = false;

  Future<void> _post() async {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(()=> _posting = true);
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'text': _textCtrl.text.trim(),
        'uid': FirebaseAuth.instance.currentUser?.uid?? 'anonymous',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _textCtrl, maxLines: 6, autofocus: true, decoration: const InputDecoration(hintText: 'What is happening in your PPA? Share gist, news, market...', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: _posting? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)), onPressed: _post, child: const Text('Post to Feed'))),
        ]),
      ),
    );
  }
}
