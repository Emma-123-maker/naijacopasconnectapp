import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint("Firebase init failed: $e");
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
      theme: ThemeData(primarySwatch: Colors.green, scaffoldBackgroundColor: const Color(0xFFF9F5F3), useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final List<Widget> screens = [ConnectTab(), JobsTab(), LodgesTab(), ProfileTab()];
  final List<String> titles = ["Naija Copas Connect", "Naija Jobs", "Corper Lodge", "Profile"];
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[currentIndex]), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(currentIndex: currentIndex, onTap: (i) => setState(() => currentIndex = i), selectedItemColor: Colors.green[700], unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed, backgroundColor: Colors.white, items: const [BottomNavigationBarItem(icon: Icon(Icons.people), label: "Connect"), BottomNavigationBarItem(icon: Icon(Icons.work), label: "Jobs"), BottomNavigationBarItem(icon: Icon(Icons.house), label: "Lodges"), BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile")]),
    );
  }
}

Future<void> openWhatsAppDirect(String phone, String msg) async {
  String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.startsWith('0')) clean = '234${clean.substring(1)}';
  final waMe = Uri.parse("https://wa.me/$clean?text=${Uri.encodeComponent(msg)}");
  final waApp = Uri.parse("whatsapp://send?phone=$clean&text=${Uri.encodeComponent(msg)}");
  try { if (await canLaunchUrl(waMe)) { await launchUrl(waMe, mode: LaunchMode.externalApplication); return; } } catch (_) {}
  try { if (await canLaunchUrl(waApp)) { await launchUrl(waApp, mode: LaunchMode.externalApplication); return; } } catch (_) {}
  try { await launchUrl(waMe, mode: LaunchMode.platformDefault); } catch (_) {}
}

// ===== CONNECT TAB - FIXED NO ROLLING VERSION =====
class ConnectTab extends StatefulWidget { ConnectTab({super.key}); @override State<ConnectTab> createState() => _ConnectTabState(); }
class _ConnectTabState extends State<ConnectTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String search = "";
  String? myUid;
  String myName = "Corper";
  bool isLoadingUid = true;

  @override void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      // Try Firebase user
      myUid = FirebaseAuth.instance.currentUser?.uid;

      final sp = await SharedPreferences.getInstance();
      myName = sp.getString('name')?? 'Corper';
      String stateBatch = sp.getString('stateBatch')?? 'Oyo State';
      String ppa = sp.getString('ppa')?? '';
      String skills = sp.getString('skills')?? '';

      // If no Firebase uid, create local uid - APP WILL NOT ROLL
      if (myUid == null) {
        String? localUid = sp.getString('local_uid');
        if (localUid == null) {
          localUid = "local_${DateTime.now().millisecondsSinceEpoch}";
          await sp.setString('local_uid', localUid);
        }
        myUid = localUid;
      }

      // Only write to Firestore if it's a real Firebase uid
      if (myUid!= null &&!myUid!.startsWith('local_')) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(myUid).set({
            'name': myName,
            'stateBatch': stateBatch,
            'ppa': ppa,
            'skills': skills,
            'uid': myUid,
            'lastSeen': FieldValue.serverTimestamp()
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    } catch (e) {
      myUid = "local_${DateTime.now().millisecondsSinceEpoch}";
    }
    if (mounted) setState(() => isLoadingUid = false);
  }

  Future<void> sendRequest(String toUid, String toName) async {
    if (myUid==null || myUid!.startsWith('local_')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enable Anonymous Login in Firebase to add friends")));
      return;
    }
    var existing = await FirebaseFirestore.instance.collection('friendRequests').where('fromUid', isEqualTo: myUid).where('toUid', isEqualTo: toUid).where('status', isEqualTo: 'pending').get();
    if (existing.docs.isNotEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request already sent"))); return; }
    await FirebaseFirestore.instance.collection('friendRequests').add({'fromUid': myUid, 'toUid': toUid, 'fromName': myName, 'toName': toName, 'status': 'pending', 'createdAt': FieldValue.serverTimestamp()});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request sent to $toName")));
  }

  Future<void> acceptRequest(String reqId, String fromUid, String fromName) async {
    if (myUid==null) return;
    await FirebaseFirestore.instance.collection('friendRequests').doc(reqId).update({'status': 'accepted'});
    await FirebaseFirestore.instance.collection('users').doc(myUid).collection('friends').doc(fromUid).set({'uid': fromUid, 'name': fromName, 'since': FieldValue.serverTimestamp()});
    await FirebaseFirestore.instance.collection('users').doc(fromUid).collection('friends').doc(myUid).set({'uid': myUid, 'name': myName, 'since': FieldValue.serverTimestamp()});
    String chatId = myUid!.compareTo(fromUid) < 0? "${myUid}_$fromUid" : "${fromUid}_${myUid}";
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({'participants': [myUid, fromUid], 'lastMessage': 'You are now friends 🎉', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> declineRequest(String reqId) async { await FirebaseFirestore.instance.collection('friendRequests').doc(reqId).update({'status': 'declined'}); }

  Future<void> createPostDialog() async {
    final textCtrl = TextEditingController();
    final sp = await SharedPreferences.getInstance();
    String myState = sp.getString('stateBatch')?? 'Oyo State';
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Create Post"), content: TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: "What's happening in your PPA?")), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () async { if (textCtrl.text.trim().isEmpty) return; try { await FirebaseFirestore.instance.collection('posts').add({'text': textCtrl.text.trim(), 'state': myState, 'uid': myUid?? 'anon', 'userName': myName, 'createdAt': FieldValue.serverTimestamp()}); } catch (_) {} if (mounted) Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post"))]));
  }

  @override Widget build(BuildContext context) {
    if (isLoadingUid) return const Center(child: CircularProgressIndicator());
    if (myUid == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("Firebase not connected"),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () { setState(() => isLoadingUid = true); _initUser(); }, child: const Text("Retry")),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton.extended(onPressed: createPostDialog, backgroundColor: Colors.green[700], icon: const Icon(Icons.add, color: Colors.white), label: const Text("Post", style: TextStyle(color: Colors.white))),
      body: Column(children: [
        Container(color: Colors.white, child: TabBar(controller: _tabController, labelColor: Colors.green[700], unselectedLabelColor: Colors.grey, indicatorColor: Colors.green[700], isScrollable: true, tabs: const [Tab(text: "Discover"), Tab(text: "Requests"), Tab(text: "Friends"), Tab(text: "Chats")])),
        Padding(padding: const EdgeInsets.all(10), child: TextField(onChanged: (v) => setState(() => search = v), decoration: InputDecoration(hintText: "Search corpers by name, PPA, skill...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        Container(color: Colors.white, padding: const EdgeInsets.all(12), child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).limit(10).snapshots(), builder: (context, snap) {
          if (snap.hasError) return Text("Error: ${snap.error}", style: const TextStyle(fontSize: 11, color: Colors.red));
          if (!snap.hasData) return const SizedBox(height: 30, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
          if (snap.data!.docs.isEmpty) return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)), child: const Text("No gist yet. Be the first! 🎉", style: TextStyle(fontSize: 12)));
          var docs = snap.data!.docs;
          return SizedBox(height: 90, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: docs.length, itemBuilder: (ctx, i) { var d = docs[i].data() as Map<String, dynamic>; return Container(width: 200, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF9F5F3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['userName']?? 'Corper', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), const SizedBox(height: 4), Expanded(child: Text(d['text']?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))), Text(d['state']?? 'Oyo', style: TextStyle(fontSize: 10, color: Colors.grey[600]))])); }));
        })),
        Expanded(child: TabBarView(controller: _tabController, children: [
          StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('users').snapshots(), builder: (ctx, snap) {
            if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            var users = snap.data!.docs.where((d) => d.id!= myUid).toList();
            if (search.isNotEmpty) { users = users.where((d) { var m = d.data() as Map<String,dynamic>; return (m['name']??'').toString().toLowerCase().contains(search.toLowerCase()) || (m['ppa']??'').toString().toLowerCase().contains(search.toLowerCase()) || (m['skills']??'').toString().toLowerCase().contains(search.toLowerCase()); }).toList(); }
            if (users.isEmpty) return const Center(child: Text("No corpers found. Invite friends!"));
            return ListView.builder(itemCount: users.length, itemBuilder: (ctx,i){ var u = users[i].data() as Map<String,dynamic>; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text((u['name']??'C')[0].toUpperCase())), title: Text(u['name']??'Corper'), subtitle: Text("${u['stateBatch']??''} - ${u['ppa']??''}\n${u['skills']??''}"), isThreeLine: true, trailing: ElevatedButton(onPressed: ()=> sendRequest(u['uid'], u['name']??'Corper'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Add")), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> UserProfileView(userData: u))))); });
          }),
          StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('friendRequests').where('toUid', isEqualTo: myUid).where('status', isEqualTo: 'pending').snapshots(), builder: (ctx,snap){
            if(snap.hasError) return Center(child: Text("Error: ${snap.error}"));
            if(!snap.hasData) return const Center(child: CircularProgressIndicator());
            if(snap.data!.docs.isEmpty) return const Center(child: Text("No friend requests"));
            return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (ctx,i){ var d = snap.data!.docs[i]; var m = d.data() as Map<String,dynamic>; return Card(child: ListTile(leading: CircleAvatar(child: Text((m['fromName']??'C')[0])), title: Text("${m['fromName']} wants to be friends"), subtitle: const Text("Accept or Decline"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 30), onPressed: ()=> acceptRequest(d.id, m['fromUid'], m['fromName'])), IconButton(icon: const Icon(Icons.cancel, color: Colors.red, size: 30), onPressed: ()=> declineRequest(d.id))]))); });
          }),
          StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('friends').snapshots(), builder: (ctx,snap){
            if(snap.hasError) return Center(child: Text("Error: ${snap.error}"));
            if(!snap.hasData) return const Center(child: CircularProgressIndicator());
            if(snap.data!.docs.isEmpty) return const Center(child: Text("No friends yet. Go to Discover!"));
            return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (ctx,i){ var m = snap.data!.docs[i].data() as Map<String,dynamic>; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text((m['name']??'C')[0].toUpperCase())), title: Text(m['name']??''), subtitle: const Text("Friends - Tap to chat"), trailing: const Icon(Icons.chat, color: Colors.green), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> ChatScreen(otherUid: m['uid'], otherName: m['name'], myUid: myUid!))))); });
          }),
          StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: myUid).orderBy('updatedAt', descending: true).snapshots(), builder: (ctx,snap){
            if(snap.hasError) return Center(child: Text("Error: ${snap.error}"));
            if(!snap.hasData) return const Center(child: CircularProgressIndicator());
            if(snap.data!.docs.isEmpty) return const Center(child: Text("No chats yet"));
            return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (ctx,i){ var d = snap.data!.docs[i]; var m = d.data() as Map<String,dynamic>; List parts = m['participants']; String otherUid = parts.firstWhere((p)=> p!= myUid, orElse: ()=> ''); return FutureBuilder<DocumentSnapshot>(future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(), builder: (ctx, userSnap){ String otherName = 'Corper'; if(userSnap.hasData && userSnap.data!= null && userSnap.data!.exists){ otherName = (userSnap.data!.data() as Map<String,dynamic>)['name']?? otherUid; } return Card(child: ListTile(leading: CircleAvatar(child: Text(otherName[0].toUpperCase())), title: Text(otherName), subtitle: Text(m['lastMessage']??''), trailing: const Icon(Icons.message, color: Colors.green), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> ChatScreen(otherUid: otherUid, otherName: otherName, myUid: myUid!))))); }); });
          }),
        ])),
      ]),
    );
  }
}

class UserProfileView extends StatelessWidget {
  final Map<String,dynamic> userData;
  const UserProfileView({super.key, required this.userData});
  @override Widget build(BuildContext context){
    String uid = userData['uid']??'';
    return Scaffold(appBar: AppBar(title: Text(userData['name']??'Profile'), backgroundColor: Colors.green[700], foregroundColor: Colors.white), body: ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: CircleAvatar(radius: 45, backgroundColor: Colors.green[100], child: Text((userData['name']??'C')[0].toUpperCase(), style: const TextStyle(fontSize: 30)))),
      const SizedBox(height: 12),
      Center(child: Text(userData['name']??'', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
      Center(child: Text(userData['stateBatch']??'', style: TextStyle(color: Colors.grey[600]))),
      const SizedBox(height: 16),
      Card(child: ListTile(leading: const Icon(Icons.school), title: const Text("PPA"), subtitle: Text(userData['ppa']??''))),
      Card(child: ListTile(leading: const Icon(Icons.star), title: const Text("Skills"), subtitle: Text(userData['skills']??''))),
      const SizedBox(height: 16),
      const Text("Posts by this corper", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots(), builder: (ctx,snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        if(snap.data!.docs.isEmpty) return const Text("No posts yet");
        return Column(children: snap.data!.docs.map((d){ var m = d.data() as Map<String,dynamic>; return Card(child: ListTile(title: Text(m['text']??''), subtitle: Text(m['state']??''))); }).toList());
      }),
    ]));
  }
}

class ChatScreen extends StatefulWidget {
  final String otherUid; final String otherName; final String myUid;
  const ChatScreen({super.key, required this.otherUid, required this.otherName, required this.myUid});
  @override State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final msgCtrl = TextEditingController();
  String chatId = "";
  @override void initState(){ super.initState(); chatId = widget.myUid.compareTo(widget.otherUid) < 0? "${widget.myUid}_${widget.otherUid}" : "${widget.otherUid}_${widget.myUid}"; }
  Future<void> sendText() async {
    if(msgCtrl.text.trim().isEmpty) return;
    String text = msgCtrl.text.trim(); msgCtrl.clear();
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({'sender': widget.myUid, 'type': 'text', 'content': text, 'createdAt': FieldValue.serverTimestamp()});
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({'participants': [widget.myUid, widget.otherUid], 'lastMessage': text, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
  Future<void> sendImage() async {
    final picker = ImagePicker(); final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); if(picked==null) return;
    final bytes = await File(picked.path).readAsBytes(); String base64Img = base64Encode(bytes);
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({'sender': widget.myUid, 'type': 'image', 'content': base64Img, 'createdAt': FieldValue.serverTimestamp()});
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({'participants': [widget.myUid, widget.otherUid], 'lastMessage': '📷 Photo', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text(widget.otherName), backgroundColor: Colors.green[700], foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.person), onPressed: () async { var userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.otherUid).get(); if (userDoc.exists && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_)=> UserProfileView(userData: userDoc.data() as Map<String,dynamic>))); })]), body: Column(children: [
      Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').orderBy('createdAt', descending: false).snapshots(), builder: (ctx,snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        if(snap.data!.docs.isEmpty) return const Center(child: Text("No messages yet. Say hello! 👋"));
        return ListView.builder(padding: const EdgeInsets.all(12), itemCount: snap.data!.docs.length, itemBuilder: (ctx,i){ var m = snap.data!.docs[i].data() as Map<String,dynamic>; bool isMe = m['sender']==widget.myUid; return Align(alignment: isMe? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isMe? Colors.green[100]: Colors.white, borderRadius: BorderRadius.circular(12)), child: m['type']=='image'? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(m['content']), width: 200, fit: BoxFit.cover)): Text(m['content']??''))); });
      })),
      Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Row(children: [
        IconButton(icon: const Icon(Icons.photo, color: Colors.green), onPressed: sendImage),
        Expanded(child: TextField(controller: msgCtrl, decoration: InputDecoration(hintText: "Message ${widget.otherName}...", filled: true, fillColor: const Color(0xFFF0F0F0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
        IconButton(icon: Icon(Icons.send, color: Colors.green[700]), onPressed: sendText),
      ])),
    ]));
  }
}

class JobsTab extends StatefulWidget { const JobsTab({super.key}); @override State<JobsTab> createState() => _JobsTabState(); }
class _JobsTabState extends State<JobsTab> {
  List<Map<String, String>> jobs = [{"title": "Home Lesson Teacher", "company": "Private Home - UI Area", "location": "Bodija, Ibadan - Close to UI second gate, 5 mins walk from main gate", "type": "Teaching / Lesson", "pay": "₦20k/month", "requirement": "Must know Maths & English", "desc": "Teach JSS2 student Maths and English 3x weekly. 2 hours per day. Parent is friendly and pays promptly.", "contact": "08012345678", "postedBy": "Emeka D.", "date": "Sep 19"}];
  String filter = "All";
  Future<void> loadJobs() async { final sp = await SharedPreferences.getInstance(); final s = sp.getString('jobs_list_v2'); if (s!= null) { try { final List l = jsonDecode(s); setState(()=> jobs = l.map((e)=> Map<String,String>.from(e)).toList()); } catch(_){} } }
  Future<void> saveJobs() async { final sp = await SharedPreferences.getInstance(); await sp.setString('jobs_list_v2', jsonEncode(jobs)); }
  @override void initState() { super.initState(); loadJobs(); }
  void addJobDialog() {
    final titleCtrl = TextEditingController(); final companyCtrl = TextEditingController(); final locationCtrl = TextEditingController(); final payCtrl = TextEditingController(); final reqCtrl = TextEditingController(); final descCtrl = TextEditingController(); final contactCtrl = TextEditingController();
    String jobType = "Teaching / Lesson";
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(title: const Text("Post Job Vacancy"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Job Title *")), const SizedBox(height: 8), TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: "Company")), const SizedBox(height: 8), DropdownButtonFormField<String>(value: jobType, decoration: const InputDecoration(labelText: "Job Type *"), items: const [DropdownMenuItem(value: "Teaching / Lesson", child: Text("Teaching / Lesson")), DropdownMenuItem(value: "PPA Opening", child: Text("PPA Opening")), DropdownMenuItem(value: "Full-time", child: Text("Full-time")), DropdownMenuItem(value: "Part-time / Side Hustle", child: Text("Part-time / Side Hustle")), DropdownMenuItem(value: "Freelance / Remote", child: Text("Freelance / Remote")), DropdownMenuItem(value: "Sales / Marketing", child: Text("Sales / Marketing"))], onChanged: (v)=> setD(()=> jobType = v!)), const SizedBox(height: 8), TextField(controller: locationCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Job Location *", border: OutlineInputBorder())), const SizedBox(height: 8), TextField(controller: payCtrl, decoration: const InputDecoration(labelText: "Pay / Salary")), const SizedBox(height: 8), TextField(controller: reqCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Requirements", border: OutlineInputBorder())), const SizedBox(height: 8), TextField(controller: descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: "Full Description *", border: OutlineInputBorder())), const SizedBox(height: 8), TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: "WhatsApp *"), keyboardType: TextInputType.phone)])), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: (){ if(titleCtrl.text.isEmpty || locationCtrl.text.isEmpty || descCtrl.text.isEmpty || contactCtrl.text.isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Required fields missing"))); return; } setState(()=> jobs.insert(0, {"title": titleCtrl.text, "company": companyCtrl.text, "location": locationCtrl.text, "type": jobType, "pay": payCtrl.text, "requirement": reqCtrl.text, "desc": descCtrl.text, "contact": contactCtrl.text, "postedBy": "You", "date": "Now"})); saveJobs(); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post Job"))])));
  }
  void deleteJob(int idx){ showDialog(context: context, builder: (ctx)=> AlertDialog(title: const Text("Delete Job?"), content: const Text("Job filled?"), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: (){ setState(()=> jobs.removeAt(idx)); saveJobs(); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete", style: TextStyle(color: Colors.white))) ])); }
  @override Widget build(BuildContext context){
    List<Map<String,String>> filtered = filter=="All"? jobs : jobs.where((j)=> j['type']!.contains(filter)).toList();
    return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton(onPressed: addJobDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)), body: Column(children: [Container(color: Colors.white, padding: const EdgeInsets.all(8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_chip("All"), _chip("Teaching"), _chip("PPA"), _chip("Part-time"), _chip("Remote"), _chip("Sales")]))), Expanded(child: filtered.isEmpty? const Center(child: Text("No jobs")) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (ctx,i){ final j = filtered[i]; final realIdx = jobs.indexOf(j); bool isMine = j['postedBy']=="You"; return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 4), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)), child: Text(j['type']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[800]))), Text(j['date']!, style: TextStyle(fontSize: 10, color: Colors.grey[500]))]), const SizedBox(height: 8), Text(j['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if(j['company']!.isNotEmpty) Text(j['company']!, style: TextStyle(fontSize: 13, color: Colors.grey[700])), const SizedBox(height: 6), Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.location_on, size: 14, color: Colors.red), const SizedBox(width: 4), Expanded(child: Text(j['location']!, style: const TextStyle(fontSize: 12)))]), if(j['pay']!.isNotEmpty)...[const SizedBox(height: 4), Row(children: [const Icon(Icons.payments, size: 14, color: Colors.green), const SizedBox(width: 4), Text(j['pay']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))])]])), const SizedBox(height: 8), Text(j['desc']!, style: const TextStyle(fontSize: 13)), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("By ${j['postedBy']}", style: TextStyle(fontSize: 11, color: Colors.grey[500])), Row(children: [if(isMine) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: ()=> deleteJob(realIdx)), ElevatedButton(onPressed: ()=> openWhatsAppDirect(j['contact']!, "Hello, I saw your job: ${j['title']}"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Apply"))])])])));} ))]));
  }
  Widget _chip(String label){ bool sel = filter==label; return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label, style: TextStyle(fontSize: 12, color: sel? Colors.white:Colors.black)), selected: sel, selectedColor: Colors.green[700], onSelected: (v)=> setState(()=> filter=label))); }
}

class LodgesTab extends StatefulWidget { const LodgesTab({super.key}); @override State<LodgesTab> createState() => _LodgesTabState(); }
class _LodgesTabState extends State<LodgesTab> {
  List<Map<String, String>> lodges = [{"category": "I HAVE Lodge Info", "area": "Bodija - UI", "location": "Opposite UI second gate, 2 mins to main gate", "price": "₦150k/year", "type": "Self-con", "desc": "Water, light, fenced", "contact": "08087654321", "postedBy": "Chioma D.", "date": "Sep 19"}];
  String filter = "All";
  Future<void> loadLodges() async { final sp = await SharedPreferences.getInstance(); final s = sp.getString('lodges_list_v3'); if (s!= null) { try { final List l = jsonDecode(s); setState(()=> lodges = l.map((e)=> Map<String,String>.from(e)).toList()); } catch(_){} } }
  Future<void> saveLodges() async { final sp = await SharedPreferences.getInstance(); await sp.setString('lodges_list_v3', jsonEncode(lodges)); }
  @override void initState() { super.initState(); loadLodges(); }
  void addLodgeDialog() {
    final areaCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    String category = "I NEED Lodge - Looking for apartment";
    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          title: const Text("Post Lodge"),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: "Post Type *"), items: const [DropdownMenuItem(value: "I NEED Lodge - Looking for apartment", child: Text("I NEED - Apartment")), DropdownMenuItem(value: "I NEED Roommate to join me", child: Text("I NEED - Roommate")), DropdownMenuItem(value: "I HAVE Lodge Info", child: Text("I HAVE - Lodge Info"))], onChanged: (v){ setD((){ category = v!; }); }),
            const SizedBox(height: 10),
            TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: "Area *", hintText: "Bodija, Akobo, Sango")),
            const SizedBox(height: 8),
            TextField(controller: locationCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Location Details *", hintText: "Type full location", border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price / Budget *")),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: "House Type", hintText: "Self-con, Single room")),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "More Info")),
            TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: "WhatsApp Number *"), keyboardType: TextInputType.phone),
          ])),
          actions: [
            TextButton(onPressed: (){ Navigator.pop(ctx); }, child: const Text("Cancel")),
            ElevatedButton(onPressed: (){
              if(areaCtrl.text.isEmpty || locationCtrl.text.isEmpty || contactCtrl.text.isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Area, Location Details & WhatsApp required")));
                return;
              }
              setState((){
                lodges.insert(0, {"category": category, "area": areaCtrl.text, "location": locationCtrl.text, "price": priceCtrl.text, "type": typeCtrl.text, "desc": descCtrl.text, "contact": contactCtrl.text, "postedBy": "You", "date": "Now"});
              });
              saveLodges();
              Navigator.pop(ctx);
            }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post"))
          ],
        );
      });
    });
  }
  void deleteLodge(int idx){ showDialog(context: context, builder: (ctx)=> AlertDialog(title: const Text("Delete Post?"), content: const Text("No longer valid? Delete it?"), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: (){ setState(()=> lodges.removeAt(idx)); saveLodges(); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete", style: TextStyle(color: Colors.white))) ])); }
  @override Widget build(BuildContext context){
    List<Map<String,String>> filtered = filter=="All"? lodges : lodges.where((l)=> l['category']!.contains(filter)).toList();
    return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton(onPressed: addLodgeDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)), body: Column(children: [Container(color: Colors.white, padding: const EdgeInsets.all(8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_chip("All"), _chip("I NEED"), _chip("I HAVE")]))), Expanded(child: filtered.isEmpty? const Center(child: Text("No lodge here. Tap + to post")) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (ctx,i){ final lg = filtered[i]; final realIdx = lodges.indexOf(lg); bool isNeed = lg['category']!.contains("NEED"); bool isMine = lg['postedBy']=="You"; return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 4), decoration: BoxDecoration(color: isNeed? Colors.orange[100]:Colors.green[100], borderRadius: BorderRadius.circular(20)), child: Text(isNeed? "LOOKING FOR" : "AVAILABLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNeed? Colors.orange[800]:Colors.green[800]))), Text(lg['date']!, style: TextStyle(fontSize: 10, color: Colors.grey[500]))]), const SizedBox(height: 8), Text(lg['area']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 6), Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.location_on, size: 16, color: Colors.red), const SizedBox(width: 6), Expanded(child: Text(lg['location']!, style: const TextStyle(fontSize: 13)))])), const SizedBox(height: 8), Text("${lg['price']!} • ${lg['type']!}", style: TextStyle(color: Colors.grey[700], fontSize: 12)), if(lg['desc']!.isNotEmpty)...[const SizedBox(height: 4), Text(lg['desc']!, style: const TextStyle(fontSize: 13))], const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("By ${lg['postedBy']}", style: TextStyle(fontSize: 11, color: Colors.grey[500])), Row(children: [if(isMine) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: ()=> deleteLodge(realIdx)), ElevatedButton(onPressed: ()=> openWhatsAppDirect(lg['contact']!, "Hello, I saw your lodge: ${lg['area']} - ${lg['location']}"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Chat"))])])])));} ))]));
  }
  Widget _chip(String label){ bool sel = filter==label; return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label, style: TextStyle(fontSize: 12, color: sel? Colors.white:Colors.black)), selected: sel, selectedColor: Colors.green[700], onSelected: (v)=> setState(()=> filter=label))); }
}

class ProfileTab extends StatefulWidget { const ProfileTab({super.key}); @override State<ProfileTab> createState() => _ProfileTabState(); }
class _ProfileTabState extends State<ProfileTab> {
  String name = "Yunus Eunice"; String stateBatch = "Oyo State - Batch C 2025"; String ppa = "Community Secondary School, Ibadan"; String skills = "Tutoring, Makeup, Baking"; String? profileImageBase64;
  @override void initState() { super.initState(); loadProfile(); }
  Future<void> loadProfile() async { final sp = await SharedPreferences.getInstance(); setState(() { name = sp.getString('name')?? name; stateBatch = sp.getString('stateBatch')?? stateBatch; ppa = sp.getString('ppa')?? ppa; skills = sp.getString('skills')?? skills; profileImageBase64 = sp.getString('profile_image'); }); }
  Future<void> saveProfile(String n, String sb, String p, String sk) async { final sp = await SharedPreferences.getInstance(); await sp.setString('name', n); await sp.setString('stateBatch', sb); await sp.setString('ppa', p); await sp.setString('skills', sk); setState(() { name = n; stateBatch = sb; ppa = p; skills = sk; }); if(FirebaseAuth.instance.currentUser!=null){ await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({'name': n, 'stateBatch': sb, 'ppa': p, 'skills': sk}, SetOptions(merge: true)); } }
  Future<void> pickImage() async { final picker = ImagePicker(); final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60); if (picked == null) return; final bytes = await File(picked.path).readAsBytes(); final base64Str = base64Encode(bytes); final sp = await SharedPreferences.getInstance(); await sp.setString('profile_image', base64Str); setState(() => profileImageBase64 = base64Str); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'))); }
  void editDialog() { final nCtrl = TextEditingController(text: name); final sbCtrl = TextEditingController(text: stateBatch); final pCtrl = TextEditingController(text: ppa); final skCtrl = TextEditingController(text: skills); showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Edit Profile"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nCtrl, decoration: const InputDecoration(labelText: "Name")), TextField(controller: sbCtrl, decoration: const InputDecoration(labelText: "State - Batch")), TextField(controller: pCtrl, decoration: const InputDecoration(labelText: "PPA")), TextField(controller: skCtrl, decoration: const InputDecoration(labelText: "Skills"))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () { saveProfile(nCtrl.text, sbCtrl.text, pCtrl.text, skCtrl.text); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Save"))])); }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFFF9F5F3), body: ListView(padding: const EdgeInsets.all(16), children: [const SizedBox(height: 20), Center(child: Stack(children: [CircleAvatar(radius: 50, backgroundColor: Colors.green[100], backgroundImage: profileImageBase64!= null? MemoryImage(base64Decode(profileImageBase64!)) : null, child: profileImageBase64 == null? Text(name.isNotEmpty? name[0].toUpperCase() : "Y", style: TextStyle(fontSize: 40, color: Colors.green[700], fontWeight: FontWeight.bold)) : null), Positioned(bottom: 0, right: 0, child: InkWell(onTap: pickImage, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.green[700], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, size: 18, color: Colors.white))))])), const SizedBox(height: 6), Center(child: TextButton(onPressed: pickImage, child: const Text("Change Photo"))), const SizedBox(height: 6), Center(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))), Center(child: Text(stateBatch, style: TextStyle(color: Colors.grey[600], fontSize: 13))), const SizedBox(height: 20), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.school, color: Colors.green[700]), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("PPA", style: TextStyle(fontWeight: FontWeight.bold)), Text(ppa)])) ])), const SizedBox(height: 10), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.star, color: Colors.green[700]), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Skills", style: TextStyle(fontWeight: FontWeight.bold)), Text(skills)])) ])), const SizedBox(height: 20), SizedBox(height: 48, child: ElevatedButton.icon(onPressed: editDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("Edit Profile"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))), ])); }
}
