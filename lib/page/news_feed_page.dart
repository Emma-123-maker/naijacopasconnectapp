import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import 'create_post_page.dart';
import '../models/post_model.dart';

class NewsFeedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Naija Copas Feed"), backgroundColor: Colors.green[700]),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.green[700],
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostPage())),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var posts = snapshot.data!.docs.map((d) => PostModel.fromDoc(d)).toList();
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCard(post: posts[i]),
          );
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostModel post;
  PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final currentUid = "YOUR_AUTH_UID"; // get from FirebaseAuth.instance.currentUser!.uid
    final isLiked = post.likes.contains(currentUid);

    return Card(margin: EdgeInsets.all(8), child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: Colors.green), title: Text(post.userName, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(timeago.format(post.createdAt.toDate()))),
      Text(post.text),
      if (post.imageUrls.isNotEmpty) SizedBox(height: 8),
      if (post.imageUrls.isNotEmpty) GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2), itemCount: post.imageUrls.length, itemBuilder: (_, i) => Image.network(post.imageUrls[i], fit: BoxFit.cover)),
      Divider(),
      Row(children: [
        IconButton(icon: Icon(isLiked? Icons.favorite : Icons.favorite_border, color: isLiked? Colors.red : Colors.grey), onPressed: () {
          var ref = FirebaseFirestore.instance.collection('posts').doc(post.id);
          if (isLiked) {
            ref.update({'likes': FieldValue.arrayRemove([currentUid]), 'likeCount': FieldValue.increment(-1)});
          } else {
            ref.update({'likes': FieldValue.arrayUnion([currentUid]), 'likeCount': FieldValue.increment(1)});
          }
        }),
        Text("${post.likeCount} likes"),
        Spacer(),
        IconButton(icon: Icon(Icons.share), onPressed: () => Share.share("${post.userName} on Naija Copas:\n\n${post.text}")),
      ])
    ])));
  }
}
