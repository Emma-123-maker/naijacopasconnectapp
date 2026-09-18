import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_post_page.dart';

class NewsFeedPage extends StatelessWidget {
  const NewsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Naija Copas Feed'), backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No posts yet. Be first to post! 🎉'));

          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var data = docs[i].data() as Map<String, dynamic>;
              var text = data['text']?? '';
              var name = data['userName']?? 'Corper';
              var time = data['createdAt']!= null? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
              return Card(margin: const EdgeInsets.all(8), child: ListTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text), const SizedBox(height: 4), Text('${time.day}/${time.month} ${time.hour}:${time.minute}', style: const TextStyle(fontSize: 11, color: Colors.grey))]),
              ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.green, onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const CreatePostPage())), child: const Icon(Icons.add)),
    );
  }
}
