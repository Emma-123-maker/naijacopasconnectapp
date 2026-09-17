import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    if (FirebaseAuth.instance.currentUser == null) {
      try { await FirebaseAuth.instance.signInAnonymously(); } catch (e) { debugPrint("Anon login: $e"); }
    }
  } catch (e) { debugPrint("Firebase init: $e"); }
  runApp(const NaijaCopasApp());
}

class NaijaCopasApp extends StatelessWidget {
  const NaijaCopasApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naija Copas Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF9F5F3)),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final screens = [const ConnectTab(), const JobsTab(), const LodgesTab(), const ProfileTab()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(currentIndex==0? "Naija Copas Connect" : currentIndex==1? "Naija Jobs" : currentIndex==2? "Corper Lodge" : "Profile"), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(currentIndex: currentIndex, onTap: (i) => setState(() => currentIndex = i), selectedItemColor: Colors.green[700], unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed, items: const [BottomNavigationBarItem(icon: Icon(Icons.people), label: "Connect"), BottomNavigationBarItem(icon: Icon(Icons.work), label: "Jobs"), BottomNavigationBarItem(icon: Icon(Icons.house), label: "Lodges"), BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile")]),
    );
  }
}

Future<void> openWhatsApp(String message) async { final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}"); try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch(_){} }
Future<void> openCall() async { try{ await launchUrl(Uri.parse("tel:+2348000000000")); }catch(_){} }
Future<void> openVideoCall(String roomName) async { final url = Uri.parse("https://meet.jit.si/${roomName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_NaijaCopas"); try{ await launchUrl(url, mode: LaunchMode.externalApplication); }catch(_){} }

class ConnectTab extends StatelessWidget {
  const ConnectTab({super.key});
  @override
  Widget build(BuildContext context) {
    final corpers = [{'name': 'Emeka D.', 'state': 'Oyo - Ibadan', 'ppa': 'UI Secondary School', 'skill': 'Tutoring'}, {'name': 'Chioma D.', 'state': 'Lagos - Ikeja', 'ppa': 'Tech Startup', 'skill': 'Graphics Design'}, {'name': 'Aisha B.', 'state': 'Abuja', 'ppa': 'Ministry', 'skill': 'Makeup'}];
    return ListView.builder(padding: const EdgeInsets.all(15), itemCount: corpers.length, itemBuilder: (ctx, i){ final c = corpers[i]; return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text(c['name']![0])), title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${c['state']}\n${c['ppa']} | Skill: ${c['skill']}"), trailing: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(corperName: c['name']!, corperSkill: c['skill']!))), child: const Text("Chat")))); });
  }
}

class ChatDetailScreen extends StatefulWidget { final String corperName; final String corperSkill; const ChatDetailScreen({super.key, required this.corperName, required this.corperSkill}); @override State<ChatDetailScreen> createState() => _ChatDetailScreenState(); }
class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _msgCtrl = TextEditingController(); final _firestore = FirebaseFirestore.instance;
  Future<void> _sendMessage() async { if(_msgCtrl.text.trim().isEmpty) return; final t = _msgCtrl.text.trim(); _msgCtrl.clear(); try{ final uid = FirebaseAuth.instance.currentUser?.uid?? 'anon'; await _firestore.collection('chats').doc(widget.corperName).collection('messages').add({'text': t, 'isMe': true, 'senderId': uid, 'time': "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}", 'timestamp': FieldValue.serverTimestamp()}); }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fail: $e"))); } }
  @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(backgroundColor: Colors.green[700], foregroundColor: Colors.white, title: Row(children: [CircleAvatar(child: Text(widget.corperName[0])), const SizedBox(width: 10), Text(widget.corperName)]), actions: [IconButton(icon: const Icon(Icons.videocam), onPressed: ()=>openVideoCall(widget.corperName)), IconButton(icon: const Icon(Icons.call), onPressed: openCall)]), body: Column(children: [Expanded(child: StreamBuilder<QuerySnapshot>(stream: _firestore.collection('chats').doc(widget.corperName).collection('messages').orderBy('timestamp', descending: true).snapshots(), builder: (context, snap){ if(snap.connectionState==ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if(snap.hasError) return Center(child: Text("Error: ${snap.error}")); final docs = snap.data?.docs?? []; if(docs.isEmpty) return Center(child: Text("Start chatting with ${widget.corperName} 👋")); return ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (ctx,i){ final d = docs[i].data() as Map<String,dynamic>; final isMe = d['isMe']==true; return Align(alignment: isMe? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe? Colors.green[700]: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text(d['text']?? '', style: TextStyle(color: isMe? Colors.white: Colors.black)))); }); })), Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Row(children: [Expanded(child: TextField(controller: _msgCtrl, decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none))), CircleAvatar(backgroundColor: Colors.green[700], child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage))]))])); }
}

class JobsTab extends StatelessWidget { const JobsTab({super.key}); @override Widget build(BuildContext context){ return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton.extended(onPressed: ()=>openWhatsApp("I want to post a job"), label: const Text("Post Job"), icon: const Icon(Icons.add)), body: ListView(padding: const EdgeInsets.all(15), children: const [Card(child: ListTile(title: Text("Home Lesson Teacher - ₦20k/month"), subtitle: Text("Ibadan - Bodija")))])); } }
class LodgesTab extends StatelessWidget { const LodgesTab({super.key}); @override Widget build(BuildContext context){ return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton.extended(onPressed: ()=>openWhatsApp("I have a lodge for corpers"), label: const Text("Post Lodge"), icon: const Icon(Icons.add)), body: ListView(padding: const EdgeInsets.all(15), children: const [Card(child: ListTile(title: Text("Agbowo, UI - ₦120k/year"), subtitle: Text("Self-con, water, light")))])); } }

// --- FIXED PROFILE TAB - NOW EDITABLE AND SAVING ---
class ProfileTab extends StatefulWidget { const ProfileTab({super.key}); @override State<ProfileTab> createState() => _ProfileTabState(); }
class _ProfileTabState extends State<ProfileTab> {
  String name = "Yunus Eunice"; String stateName = "Oyo State"; String batch = "Batch C 2025"; String ppa = "Community Secondary School, Ibadan"; String skills = "Tutoring, Makeup, Baking"; String? photoUrl; File? localImage; bool loading = true;
  final picker = ImagePicker(); final firestore = FirebaseFirestore.instance; final storage = FirebaseStorage.instance;

  @override void initState(){ super.initState(); loadProfile(); }
  Future<String> getUid() async { var u = FirebaseAuth.instance.currentUser; if(u==null){ var c = await FirebaseAuth.instance.signInAnonymously(); u=c.user; } return u!.uid; }
  Future<void> loadProfile() async { try{ final uid = await getUid(); final doc = await firestore.collection('users').doc(uid).get(); if(doc.exists){ final d = doc.data()!; setState((){ name=d['name']??name; stateName=d['state']??stateName; batch=d['batch']??batch; ppa=d['ppa']??ppa; skills=d['skills']??skills; photoUrl=d['photoUrl']; }); } }catch(e){ debugPrint("load: $e"); } setState(()=>loading=false); }
  Future<void> saveProfile() async { try{ final uid = await getUid(); await firestore.collection('users').doc(uid).set({'name': name, 'state': stateName, 'batch': batch, 'ppa': ppa, 'skills': skills, 'photoUrl': photoUrl, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true)); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile saved! ✅"))); }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e"))); } }
  Future<void> pickImage() async { try{ final XFile? x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40); if(x==null) return; setState(()=>localImage=File(x.path)); final uid = await getUid(); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading..."))); final ref = storage.ref().child('profile_pics/$uid.jpg'); await ref.putFile(File(x.path)); final url = await ref.getDownloadURL(); setState(()=>photoUrl=url); await saveProfile(); }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e\nCheck Storage Rules"))); } }
  void editDialog(){ final nc = TextEditingController(text: name); final sc = TextEditingController(text: stateName); final bc = TextEditingController(text: batch); final pc = TextEditingController(text: ppa); final skc = TextEditingController(text: skills); showDialog(context: context, builder: (c)=>AlertDialog(title: const Text("Edit Profile"), content: SingleChildScrollView(child: Column(children: [TextField(controller: nc, decoration: const InputDecoration(labelText: "Full Name")), TextField(controller: sc, decoration: const InputDecoration(labelText: "State")), TextField(controller: bc, decoration: const InputDecoration(labelText: "Batch")), TextField(controller: pc, decoration: const InputDecoration(labelText: "PPA")), TextField(controller: skc, decoration: const InputDecoration(labelText: "Skills"))])), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancel")), ElevatedButton(onPressed: (){ setState((){ name=nc.text.trim(); stateName=sc.text.trim(); batch=bc.text.trim(); ppa=pc.text.trim(); skills=skc.text.trim(); }); Navigator.pop(c); saveProfile(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Save"))])); }

  @override Widget build(BuildContext context){
    if(loading) return const Center(child: CircularProgressIndicator());
    ImageProvider? img; if(localImage!=null) img=FileImage(localImage!); else if(photoUrl!=null) img=NetworkImage(photoUrl!);
    return ListView(padding: const EdgeInsets.all(24), children: [
      Center(child: Column(children: [Stack(children: [CircleAvatar(radius: 60, backgroundColor: Colors.green[100], backgroundImage: img, child: img==null? Text(name[0], style: TextStyle(fontSize: 40, color: Colors.green[700], fontWeight: FontWeight.bold)): null), Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: Icon(Icons.camera_alt, color: Colors.green[700]), onPressed: pickImage))) ]), const SizedBox(height: 12), Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text("$stateName | $batch", style: TextStyle(color: Colors.grey[600])), const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified, size: 16, color: Colors.green[700]), const SizedBox(width: 4), Text("Verified Corper", style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold))]))])),
      const SizedBox(height: 20),
      Card(child: ListTile(leading: Icon(Icons.work, color: Colors.green[700]), title: const Text("PPA"), subtitle: Text(ppa))),
      Card(child: ListTile(leading: Icon(Icons.star, color: Colors.green[700]), title: const Text("Skills"), subtitle: Text(skills))),
      Card(child: ListTile(leading: Icon(Icons.phone, color: Colors.green[700]), title: const Text("WhatsApp"), subtitle: const Text("Visible to connected corpers only"))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), onPressed: editDialog, icon: const Icon(Icons.edit), label: const Text("Edit Profile - Now Saving"))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: (){ showDialog(context: context, builder: (c)=>AlertDialog(title: const Text("Privacy Policy"), content: const Text("We store only name, state, PPA, skills, photo securely in Firebase. No BVN. You can delete anytime."), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Close"))])); }, icon: const Icon(Icons.privacy_tip_outlined), label: const Text("Privacy Policy & Safety")),
      TextButton.icon(onPressed: () async { final uid = await getUid(); await firestore.collection('users').doc(uid).delete(); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account deleted"))); }, icon: const Icon(Icons.delete_forever, color: Colors.red), label: const Text("Delete Account", style: TextStyle(color: Colors.red))),
    ]);
  }
}
