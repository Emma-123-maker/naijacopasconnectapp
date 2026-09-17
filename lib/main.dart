import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        debugPrint("Anonymous login failed - enable in Firebase Console: $e");
      }
    }
  } catch (e) {
    debugPrint("Firebase init failed but app continues: $e");
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
        elevation: 0,
      ),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
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

Future<void> openWhatsApp(String message) async {
  final encoded = Uri.encodeComponent(message);
  final url = Uri.parse("https://wa.me/?text=$encoded");
  try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) { debugPrint("WhatsApp fail: $e"); }
}
Future<void> openCall() async {
  final url = Uri.parse("tel:+2348000000000");
  try { await launchUrl(url); } catch (e) { debugPrint("Call fail: $e"); }
}
Future<void> openVideoCall(String roomName) async {
  final url = Uri.parse("https://meet.jit.si/${roomName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_NaijaCopas");
  try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) { debugPrint("Video fail: $e"); }
}

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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text(c['name']![0], style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold))),
            title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Text("${c['state']}", style: const TextStyle(fontSize: 12)),
              Text("${c['ppa']} | Skill: ${c['skill']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Row(children: [Icon(Icons.verified, size: 14, color: Colors.green[700]), const SizedBox(width: 4), Text("Verified Corper", style: TextStyle(fontSize: 10, color: Colors.green[700]))]),
            ]),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[50], foregroundColor: Colors.green[700], elevation: 0),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(corperName: c['name']!, corperSkill: c['skill']!))),
              child: const Text("Chat"),
            ),
          ),
        );
      },
    );
  }
}

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
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _firestore.collection('chats').doc(widget.corperName).collection('messages').add({
        'text': text,
        'isMe': true,
        'senderId': user?.uid?? 'anon',
        'time': "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700], foregroundColor: Colors.white,
        title: Row(children: [CircleAvatar(child: Text(widget.corperName[0])), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.corperName, style: const TextStyle(fontSize: 16)), Text(widget.corperSkill, style: const TextStyle(fontSize: 11))])]),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () => openVideoCall(widget.corperName)),
          IconButton(icon: const Icon(Icons.call), onPressed: openCall),
          PopupMenuButton(itemBuilder: (c) => [const PopupMenuItem(value: 'report', child: Text("Report User")), const PopupMenuItem(value: 'block', child: Text("Block User"))], onSelected: (v){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$v - Safety feature coming"))); }),
        ],
      ),
      body: Column(children: [
        Container(width: double.infinity, color: Colors.amber[50], padding: const EdgeInsets.all(8), child: Row(children: [Icon(Icons.safety_check, size: 16, color: Colors.amber[800]), const SizedBox(width: 6), Expanded(child: Text("Safety: Meet in public place. Don't share BVN/password.", style: TextStyle(fontSize: 11, color: Colors.amber[800])))])),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('chats').doc(widget.corperName).collection('messages').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 40), const SizedBox(height: 10), Text("Chat error: ${snapshot.error}", textAlign: TextAlign.center), const SizedBox(height: 10), const Text("Fix: Firebase Console > Firestore > Rules > allow read,write: if true", style: TextStyle(fontSize: 12), textAlign: TextAlign.center)])));
              }
              final docs = snapshot.data?.docs?? [];
              if (docs.isEmpty) return Center(child: Text("Start chatting with ${widget.corperName} 👋\nBe respectful, you're a corper!", textAlign: TextAlign.center));
              return ListView.builder(
                reverse: true, padding: const EdgeInsets.all(12), itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final isMe = data['isMe'] == true;
                  return Align(
                    alignment: isMe? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.75), decoration: BoxDecoration(color: isMe? Colors.green[700] : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['text']?? '', style: TextStyle(color: isMe? Colors.white : Colors.black)), const SizedBox(height: 4), Text(data['time']?? '', style: TextStyle(fontSize: 10, color: isMe? Colors.white70 : Colors.grey))])),
                  );
                },
              );
            },
          ),
        ),
        Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Row(children: [Expanded(child: TextField(controller: _msgCtrl, onSubmitted: (_)=>_sendMessage(), decoration: InputDecoration(hintText: "Type a message...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)))), const SizedBox(width: 8), CircleAvatar(backgroundColor: Colors.green[700], child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage))]),
        ),
      ]),
    );
  }
}

class JobsTab extends StatelessWidget {
  const JobsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final jobs = [{"title": "Home Lesson Teacher", "pay": "₦20k/month", "location": "Ibadan - Bodija", "type": "Part-time", "desc": "Need corper to teach JSS2 Maths 3x weekly"}];
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => openWhatsApp("Hello, I want to post a job on Naija Copas Connect: "), label: const Text("Post Job"), icon: const Icon(Icons.add), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: ListView.builder(padding: const EdgeInsets.all(15), itemCount: jobs.length, itemBuilder: (ctx, i){
        final j = jobs[i];
        return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(j["title"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)), child: Text(j["pay"]!, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12))) ]), const SizedBox(height: 8), Text(j["desc"]!, style: TextStyle(color: Colors.grey[700], fontSize: 13)), const SizedBox(height: 8), Row(children: [Icon(Icons.location_on, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Text(j["location"]!, style: TextStyle(fontSize: 12, color: Colors.grey[500])), const SizedBox(width: 12), Icon(Icons.access_time, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Text(j["type"]!, style: TextStyle(fontSize: 12, color: Colors.grey[500]))]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: ()=>openWhatsApp("I am interested in Job: ${j["title"]} in ${j["location"]}"), child: const Text("Apply via WhatsApp"))) ])));
      }),
    );
  }
}

class LodgesTab extends StatelessWidget {
  const LodgesTab({super.key});
  @override
  Widget build(BuildContext context) {
    final lodges = [{"area": "Agbowo, UI", "price": "₦120k/year", "desc": "Self-con, water, light, 2 corpers needed. Close to campus, safe area.", "type": "Self-contain"}];
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => openWhatsApp("Hello, I have a lodge for corpers: "), label: const Text("Post Lodge"), icon: const Icon(Icons.add), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: ListView.builder(padding: const EdgeInsets.all(15), itemCount: lodges.length, itemBuilder: (ctx, i){
        final l = lodges[i];
        return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l["area"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(l["price"]!, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold))]), const SizedBox(height: 6), Text(l["desc"]!, style: TextStyle(color: Colors.grey[700], fontSize: 13)), const SizedBox(height: 8), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)), child: Text(l["type"]!, style: TextStyle(fontSize: 11, color: Colors.blue[700]))), const SizedBox(width: 8), const Icon(Icons.verified_user, size: 14, color: Colors.green), const SizedBox(width: 4), Text("Verified by Corper", style: TextStyle(fontSize: 11, color: Colors.green[700]))]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: ()=>openWhatsApp("I am interested in Lodge: ${l["area"]} - ${l["price"]}"), child: const Text("Contact Owner"))) ])));
      }),
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
  File? profileImage; final ImagePicker picker = ImagePicker();
  Future<void> pickImage() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (picked!= null) setState(() => profileImage = File(picked.path));
  }
  void _showPrivacy() {
    showDialog(context: context, builder: (c)=>AlertDialog(
      title: const Text("Privacy Policy - Naija Copas Connect"),
      content: const SingleChildScrollView(child: Text("We respect your privacy.\n\n1. We don't collect BVN, password, or bank details.\n2. Your location is only shared if you allow.\n3. Chats are stored securely in Firebase.\n4. You can delete your account anytime.\n5. We never sell your data.\n\nBuilt by corpers for corpers.")),
      actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Close"))],
    ));
  }
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Center(child: Column(children: [
        Stack(children: [
          CircleAvatar(radius: 60, backgroundColor: Colors.green[100], backgroundImage: profileImage!= null? FileImage(profileImage!) : null, child: profileImage == null? Text(name[0], style: TextStyle(fontSize: 40, color: Colors.green[700], fontWeight: FontWeight.bold)) : null),
          Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: Icon(Icons.camera_alt, color: Colors.green[700]), onPressed: pickImage))),
        ]),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text("$state | $batch", style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified, size: 16, color: Colors.green[700]), const SizedBox(width: 4), Text("Verified Corper", style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold))])),
      ])),
      const SizedBox(height: 20),
      Card(child: ListTile(leading: Icon(Icons.work, color: Colors.green[700]), title: const Text("PPA"), subtitle: Text(ppa))),
      Card(child: ListTile(leading: Icon(Icons.star, color: Colors.green[700]), title: const Text("Skills"), subtitle: const Text("Tutoring, Makeup, Baking"))),
      Card(child: ListTile(leading: Icon(Icons.phone, color: Colors.green[700]), title: const Text("WhatsApp"), subtitle: const Text("Visible to connected corpers only"), trailing: Icon(Icons.lock, size: 16, color: Colors.grey[400]))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), onPressed: (){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit profile coming - will save to Firebase"))); }, icon: const Icon(Icons.edit), label: const Text("Edit Profile"))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _showPrivacy, icon: const Icon(Icons.privacy_tip_outlined), label: const Text("Privacy Policy & Safety")),
      const SizedBox(height: 8),
      TextButton.icon(onPressed: (){ showDialog(context: context, builder: (c)=>AlertDialog(title: const Text("Delete Account?"), content: const Text("This will remove your data. This action is permanent. Continue?"), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancel")), TextButton(onPressed: (){ Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account deletion - will connect to Firebase Auth delete")) ); }, child: const Text("Delete", style: TextStyle(color: Colors.red)))])); }, icon: const Icon(Icons.delete_forever, color: Colors.red), label: const Text("Delete Account", style: TextStyle(color: Colors.red))),
      const SizedBox(height: 20),
      Center(child: Column(children: [Text("Naija Copas Connect v1.0.1", style: TextStyle(color: Colors.grey[500], fontSize: 12)), const SizedBox(height: 4), Text("Reliable & Trustworthy - Built for Corpers", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12))])),
    ]);
  }
}
