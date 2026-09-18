import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final textController = TextEditingController();
  List<XFile> pickedImages = [];
  XFile? pickedVideo;
  Uint8List? videoThumb;
  bool loading = false;
  double progress = 0;

  Future pickVideo() async {
    var video = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: Duration(seconds: 60));
    if (video == null) return;

    // Check size - limit 50MB
    var file = File(video.path);
    if (await file.length() > 50 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Video too big, max 50MB / 60 secs")));
      return;
    }

    var thumb = await VideoThumbnail.thumbnailData(video: video.path, imageFormat: ImageFormat.JPEG, quality: 75);
    setState(() {
      pickedVideo = video;
      videoThumb = thumb;
      pickedImages = []; // if video picked, clear images (1 post = video OR images)
    });
  }

  Future<void> createPost() async {
    if (textController.text.trim().isEmpty) return;
    setState(() { loading = true; progress = 0; });

    List<String> imageUrls = [];
    String? videoUrl;

    try {
      // Upload images if any
      for (var img in pickedImages) {
        var ref = FirebaseStorage.instance.ref().child('posts/images/${DateTime.now().millisecondsSinceEpoch}_${img.name}');
        await ref.putFile(File(img.path));
        imageUrls.add(await ref.getDownloadURL());
      }

      // Upload video if any
      if (pickedVideo!= null) {
        var ref = FirebaseStorage.instance.ref().child('posts/videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
        var uploadTask = ref.putFile(File(pickedVideo!.path));
        uploadTask.snapshotEvents.listen((s) {
          setState(() => progress = s.bytesTransferred / s.totalBytes);
        });
        await uploadTask;
        videoUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'userName': FirebaseAuth.instance.currentUser!.displayName?? 'Corper',
        'userPhoto': FirebaseAuth.instance.currentUser!.photoURL,
        'text': textController.text.trim(),
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'videoThumb': null, // you can upload thumb too if you want
        'likes': [],
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'state': 'Oyo',
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Post"), backgroundColor: Colors.green[700], actions: [
        TextButton(onPressed: loading? null : createPost, child: Text("POST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
      ]),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: textController, maxLines: 5, decoration: InputDecoration(hintText: "What's happening? CDS, PPA, Carnival...", border: OutlineInputBorder())),
          SizedBox(height: 12),
          Row(children: [
            ElevatedButton.icon(onPressed: () async {
              var imgs = await ImagePicker().pickMultiImage();
              if (imgs.isNotEmpty) setState(() { pickedImages = imgs; pickedVideo = null; });
            }, icon: Icon(Icons.image), label: Text("Images")),
            SizedBox(width: 10),
            ElevatedButton.icon(onPressed: pickVideo, icon: Icon(Icons.videocam), label: Text("Video"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700])),
          ]),
          SizedBox(height: 12),
          if (pickedImages.isNotEmpty) Wrap(spacing: 6, children: pickedImages.map((e) => Image.file(File(e.path), width: 80, height: 80, fit: BoxFit.cover)).toList()),
          if (pickedVideo!= null && videoThumb!= null) Column(children: [
            Stack(alignment: Alignment.center, children: [
              Image.memory(videoThumb!, width: double.infinity, height: 200, fit: BoxFit.cover),
              Icon(Icons.play_circle_fill, size: 60, color: Colors.white)
            ]),
            Text(pickedVideo!.name, style: TextStyle(fontSize: 12))
          ]),
          if (loading) Padding(padding: EdgeInsets.only(top: 20), child: Column(children: [
            LinearProgressIndicator(value: progress),
            Text("${(progress * 100).toStringAsFixed(0)}% uploading...")
          ]))
        ]),
      ),
    );
  }
}
