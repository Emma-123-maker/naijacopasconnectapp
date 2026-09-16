import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Sign in anonymously so chat works
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  runApp(const NaijaCopasApp());
}

class NaijaCopasApp extends StatelessWidget {
  const NaijaCopasApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naija Copas Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F5F3),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final screens = [const ConnectTab(), const JobsTab(), const LodgesTab(), const ProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentIndex==0? "Naija Copas Connect" : currentIndex==1? "Naija Jobs" : currentIndex==2? "Corper Lodge" : "Profile"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Connect"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Jobs"),
          BottomNavigationBarItem(icon: Icon(Icons.house), label: "Lodges"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// Your original functions - kept!
Future<void> openWhatsApp(String message) async {
  final encoded = Uri.encodeComponent(message);
  final url = Uri.parse("https://wa.me/?text=$encoded");
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<void> openCall() async {
  final url = Uri.parse("tel:+2348000000000");
  await launchUrl(url);
}

Future<void> openVideoCall(String roomName) async {
  final url = Uri.parse("https://meet.jit.si/${roomName.replaceAll(' ', '_')}");
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

class ChatMessage {
  String text; bool isMe; String time;
  ChatMessage({required this.text, required this.isMe, required this.time});
}

// CONNECT TAB - with real people list
class ConnectTab extends StatelessWidget {
  const ConnectTab({super.key});

  @override
  Widget build(BuildContext context) {
    final corpers = [
      {'name': 'Emeka D.', 'state': 'Oyo - Ibadan', 'ppa': 'UI Secondary School', 'skill': 'Tutoring'},
      {'name': 'Chioma D.', 'state': 'Lagos - Ikeja', 'ppa': 'Tech Startup', 'skill': 'Graphics Design'},
      {'name': 'Aisha B.', 'state': 'Abuja', 'ppa': 'Ministry', 'skill': 'Makeup'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: corpers.length,
      itemBuilder: (ctx, i) {
        final c = corpers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text(c['name']![0])),
            title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${c['state']}\n${c['ppa']} | Skill: ${c['skill']}"),
            trailing: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(corperName: c['name']!, corperSkill: c['skill']!))),
              child: const Text("Chat"),
            ),
          ),
        );
      },
    );
  }
}

// CHAT DETAIL - NOW REAL FIREBASE CHAT!
class ChatDetailScreen extends StatefulWidget {
  final String corperName; final String corperSkill;
  const ChatDetailScreen({super.key, required this.corperName, required this.corperSkill});
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    await _firestore.collection('chats').doc(widget.corperName).collection('messages').add({
      'text': _msgCtrl.text.trim(),
      'isMe': true,
      'senderId': user?.uid,
      'time': "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
      'timestamp': FieldValue.serverTimestamp(),
    });
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700], foregroundColor: Colors.white,
        title: Row(children: [CircleAvatar(child: Text(widget.corperName[0])), const SizedBox(width: 10), Text(widget.corperName)]),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () => openVideoCall(widget.corperName)),
          IconButton(icon: const Icon(Icons.call), onPressed: openCall),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('chats').doc(widget.corperName).collection('messages').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(child: Text("Start chatting with ${widget.corperName} - Real-time!"));
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final isMe = data['isMe'] == true;
                  return Align(
                    alignment: isMe? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isMe? Colors.green[700] : Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['text']?? '', style: TextStyle(color: isMe? Colors.white : Colors.black)), Text(data['time']?? '', style: TextStyle(fontSize: 10, color: isMe? Colors.white70 : Colors.grey))]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Row(children: [
          Expanded(child: TextField(controller: _msgCtrl, decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none))),
          const SizedBox(width: 8),
          CircleAvatar(backgroundColor: Colors.green[700], child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage)),
        ])),
      ]),
    );
  }
}

class JobsTab extends StatelessWidget {
  const JobsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final jobs = [{"title": "Home Lesson Teacher", "pay": "#20k/month", "location": "Ibadan - Bodija", "type": "Part-time"}];
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => openWhatsApp("I want to post a job"), label: const Text("Post Job"), icon: const Icon(Icons.add)),
      body: ListView.builder(padding: const EdgeInsets.all(15), itemCount: jobs.length, itemBuilder: (ctx, i) => Card(child: ListTile(title: Text(jobs[i]["title"]!)))),
    );
  }
}

class LodgesTab extends StatelessWidget {
  const LodgesTab({super.key});
  @override
  Widget build(BuildContext context) {
    final lodges = [{"area": "Agbowo, UI", "price": "#120k/year", "desc": "Self-con, water, light, 2 corpers needed"}];
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => openWhatsApp("I have a lodge for corpers"), label: const Text("Post Lodge"), icon: const Icon(Icons.add)),
      body: ListView.builder(padding: const EdgeInsets.all(15), itemCount: lodges.length, itemBuilder: (ctx, i) => Card(child: ListTile(title: Text(lodges[i]["area"]!)))),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String name = "Yunus Eunice"; String state = "Oyo State"; String batch = "Batch C 2025"; String ppa = "Community Secondary School, Ibadan";
  File? profileImage;
  final ImagePicker picker = ImagePicker();
  Future<void> pickImage() async { final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); if (picked!= null) setState(() => profileImage = File(picked.path)); }
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Center(child: Column(children: [
        Stack(children: [
          CircleAvatar(radius: 60, backgroundColor: Colors.green[100], backgroundImage: profileImage!= null? FileImage(profileImage!) : null, child: profileImage == null? Text(name[0], style: const TextStyle(fontSize: 40)) : null),
          Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.green), onPressed: pickImage))),
        ]),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text("$state | $batch", style: TextStyle(color: Colors.grey[600])),
      ])),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.work, color: Colors.green[700]), const SizedBox(width: 8), const Expanded(child: Text("Naija Connect - Chat + Video Call", style: TextStyle(fontWeight: FontWeight.w500))) ])),
      const SizedBox(height: 20),
      Card(child: ListTile(leading: Icon(Icons.work, color: Colors.green[700]), title: const Text("PPA"), subtitle: Text(ppa))),
      Card(child: ListTile(leading: Icon(Icons.star, color: Colors.green[700]), title: const Text("Skills"), subtitle: const Text("Tutoring, Makeup, Baking"))),
      Card(child: ListTile(leading: Icon(Icons.phone, color: Colors.green[700]), title: const Text("WhatsApp"), subtitle: const Text("Visible to connected corpers only"))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text("Edit Profile"))),
      const SizedBox(height: 20),
      Center(child: Text("Naija Copas Connect - Chat + Video Call", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold))),
    ]);
  }
}
