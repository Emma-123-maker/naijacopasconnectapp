import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  String id;
  String uid, userName, text;
  List<String> imageUrls;
  String? videoUrl;
  List likes;
  int likeCount;
  Timestamp createdAt;

  PostModel({required this.id, required this.uid, required this.userName, required this.text, required this.imageUrls, this.videoUrl, required this.likes, required this.likeCount, required this.createdAt});

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      uid: data['uid'],
      userName: data['userName'],
      text: data['text'],
      imageUrls: List<String>.from(data['imageUrls']?? []),
      videoUrl: data['videoUrl'],
      likes: data['likes']?? [],
      likeCount: data['likeCount']?? 0,
      createdAt: data['createdAt'],
    );
  }
}
