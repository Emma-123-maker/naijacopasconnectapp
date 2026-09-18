import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    if (FirebaseAuth.instance.currentUser == null) {
      try { await FirebaseAuth.instance.signInAnonymously(); } catch(_){}
    }
  } catch(_){}
  runApp(const NaijaCopasApp());
}

class NaijaCopasApp extends StatelessWidget {
  const NaijaCopasApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naija Copas Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF9F5F3)),
      home: const HomeScreen()
    );
  }
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final screens = [const ConnectTab(), const JobsTab(), const LodgesTab(), const ProfileTab()];
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(["Naija Copas Connect","Naija Jobs","Corper Lodge","Profile"][currentIndex]), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(currentIndex: currentIndex, onTap: (i)=>setState(()=>currentIndex=i), selectedItemColor: Colors.green[700], unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed, items: const [BottomNavigationBarItem(icon: Icon(Icons.people), label: "Connect"), BottomNavigationBarItem(icon: Icon(Icons.work), label: "Jobs"), BottomNavigationBarItem(icon: Icon(Icons.house), label: "Lodges"), BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile")]),
    );
  }
}

Future<void> openWhatsAppDirect(String phone, String msg) async {
  String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if(cleanPhone.startsWith('0')) cleanPhone = '234${cleanPhone.substring(1)}';
  final url = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}");
  try{ await launchUrl(url, mode: LaunchMode.externalApplication); }catch(_){
    try{ await launchUrl(Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msg)}"), mode: LaunchMode.externalApplication); }catch(_){}
  }
}
Future<void> openCall(String phone) async { try{ String clean = phone.replaceAll(RegExp(r'[^0-9+]'), ''); await launchUrl(Uri.parse("tel:$clean")); }catch(_){} }
Future<void> openVideoCall(String room) async { try{ await launchUrl(Uri.parse("https://meet.jit.si/${room.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_NaijaCopas"), mode: LaunchMode.externalApplication); }catch(_){} }

void showPosterProfile(BuildContext context, Map<String,String> item, bool isJob) {
  String postedBy = item['postedBy']?? 'Corper';
  String contact = item['contact']?? '';
  String location = isJob? (item['location']?? '') : (item['area']?? '');
  String title = isJob? (item['title']?? '') : (item['area']?? '');
  showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx){
    return Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
      const SizedBox(height: 16),
      CircleAvatar(radius: 40, backgroundColor: Colors.green[100], child: Text(postedBy[0].toUpperCase(), style: TextStyle(fontSize: 30, color: Colors.green[700], fontWeight: FontWeight.bold))),
      const SizedBox(height: 12),
      Text(postedBy, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text("Posted $title", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      const SizedBox(height: 16),
      Card(child: ListTile(leading: Icon(Icons.location_on, color: Colors.green[700]), title: const Text("Location"), subtitle: Text(location))),
      Card(child: ListTile(leading: Icon(Icons.phone, color: Colors.green[700]), title: const Text("WhatsApp"), subtitle: Text(contact))),
      Card(child: ListTile(leading: Icon(Icons.verified, color: Colors.green[700]), title: const Text("Verified Corper"), subtitle: const Text("NYSC Member - Batch C 2025"))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: (){
        Navigator.pop(ctx);
        openWhatsAppDirect(contact, isJob? "Hello $postedBy, I saw your job posting *$title* on Naija Copas Connect. I'm interested. Is it still available?" : "Hello $postedBy, I'm interested in your lodge at $title - ${item['price']} posted on Naija Copas Connect. Is it still available?");
      }, icon: const Icon(Icons.chat), label: Text("Chat with $postedBy on WhatsApp"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white))),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: (){ Navigator.pop(ctx); openCall(contact); }, icon: const Icon(Icons.call), label: const Text("Call"))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: (){ Navigator.pop(ctx); openVideoCall(postedBy); }, icon: const Icon(Icons.videocam), label: const Text("Video Call")))]),
    ]));
  });
}

// CONNECT TAB - FIXED WITH FEED
class ConnectTab extends StatefulWidget { const ConnectTab({super.key}); @override State<ConnectTab> createState() => _ConnectTabState(); }
class _ConnectTabState extends State<ConnectTab> {
  String search = "";
  final corpers = [
    {'name': 'Emeka D.', 'state': 'Oyo - Ibadan', 'ppa': 'UI Secondary School', 'skill': 'Tutoring, Maths', 'batch': 'Batch C 2025', 'about': 'NYSC Corper serving at UI. I teach Maths and Physics for JSS/SS. 2 years experience. Available evenings.', 'phone': '08012345678'},
    {'name': 'Chioma D.', 'state': 'Lagos - Ikeja', 'ppa': 'Tech Startup, Yaba', 'skill': 'Graphics Design, Branding', 'batch': 'Batch B 2025', 'about': 'Creative designer. I design logos, flyers, business cards for corpers at affordable price.', 'phone': '08023456789'},
    {'name': 'Aisha B.', 'state': 'Abuja', 'ppa': 'Ministry of Education', 'skill': 'Makeup, Gele', 'batch': 'Batch C 2025', 'about': 'Professional makeup artist. Bridal, birthday glam. Based in Wuse. Home service available.', 'phone': '08034567890'},
    {'name': 'Tunde O.', 'state': 'Oyo - Ogbomoso', 'ppa': 'LAUTECH', 'skill': 'Web Dev, Flutter', 'batch': 'Batch A 2025', 'about': 'Building apps for corpers. Flutter developer. Can help with final year projects.', 'phone': '08045678901'},
  ];

  Future<void> createPostDialog() async {
    final textCtrl = TextEditingController();
    final sp = await SharedPreferences.getInstance();
    String myName = sp.getString('name')?? 'Yunus Eunice';
    if(!mounted) return;
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      title: const Text("New Post"),
      content: TextField(controller: textCtrl, maxLines: 3, decoration: const InputDecoration(hintText: "Hello Oyo people...")),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          if(textCtrl.text.trim().isEmpty) return;
          await FirebaseFirestore.instance.collection('posts').add({
            'text': textCtrl.text.trim(),
            'state': 'Oyo',
            'uid': FirebaseAuth.instance.currentUser?.uid?? 'test123',
            'userName': myName,
            'likeCount': 0,
            'commentCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          if(context.mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post"))
      ],
    ));
  }

  @override Widget build(BuildContext context){
    final filtered = corpers.where((c)=> c['name']!.toLowerCase().contains(search.toLowerCase()) || c['skill']!.toLowerCase().contains(search.toLowerCase()) || c['state']!.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: createPostDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v)=>setState(()=>search=v), decoration: InputDecoration(hintText: "Search name, skill, state...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if(snap.hasError) return Padding(padding: const EdgeInsets.all(8), child: Text("Feed error: ${snap.error}", style: const TextStyle(fontSize: 11, color: Colors.red)));
            if(!snap.hasData) return const SizedBox();
            if(snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text("No posts yet. Tap + to post", style: TextStyle(fontSize: 12)));
            var docs = snap.data!.docs;
            return SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: docs.length, padding: const EdgeInsets.symmetric(horizontal: 12), itemBuilder: (ctx,i){
              var d = docs[i].data() as Map<String, dynamic>;
              Timestamp? ts = d['createdAt'] as Timestamp?;
              return Container(width: 240, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['userName']??'Corper', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 4), Text(d['text']??'', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)), const Spacer(), Text("${d['state']??''} • ${ts!=null? '${ts.toDate().day}/${ts.toDate().month}' : 'now'}", style: TextStyle(fontSize: 10, color: Colors.grey[600]))]));
            }));
          }
        ),
        const Divider(height: 1),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (ctx,i){ final c=filtered[i]; return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)]), child: InkWell(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>FullCorperProfileScreen(corper: c))), borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [CircleAvatar(radius: 28, backgroundColor: Colors.green[100], child: Text(c['name']![0], style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text("${c['state']} • ${c['batch']}", style: TextStyle(fontSize: 11, color: Colors.grey[600])), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Text(c['skill']!, style: TextStyle(fontSize: 11, color: Colors.green[700]))), const SizedBox(height: 4), Text("Tap to view full profile", style: TextStyle(fontSize: 10, color: Colors.grey[500]))])), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, minimumSize: const Size(60, 36)), onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>ChatDetailScreen(corperName: c['name']!, corperSkill: c['skill']!))), child: const Text("Chat"))])))); }))
      ]),
    );
  }
}

class FullCorperProfileScreen extends StatelessWidget {
  final Map<String, String> corper;
  const FullCorperProfileScreen({super.key, required this.corper});
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text(corper['name']!), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: Column(children: [CircleAvatar(radius: 50, backgroundColor: Colors.green[100], child: Text(corper['name']![0], style: TextStyle(fontSize: 40, color: Colors.green[700], fontWeight: FontWeight.bold))), const SizedBox(height: 12), Text(corper['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text("${corper['state']} • ${corper['batch']}", style: TextStyle(color: Colors.grey[600])), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified, size: 16, color: Colors.green[700]), const SizedBox(width: 4), Text("Verified Corper", style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold))]))])),
        const SizedBox(height: 24),
        Card(child: ListTile(leading: Icon(Icons.school, color: Colors.green[700]), title: const Text("PPA", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(corper['ppa']!))),
        Card(child: ListTile(leading: Icon(Icons.star, color: Colors.green[700]), title: const Text("Skills", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(corper['skill']!))),
        Card(child: ListTile(leading: Icon(Icons.info_outline, color: Colors.green[700]), title: const Text("About", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(corper['about']!))),
        Card(child: ListTile(leading: Icon(Icons.phone, color: Colors.green[700]), title: const Text("Contact"), subtitle: Text(corper['phone']!))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>ChatDetailScreen(corperName: corper['name']!, corperSkill: corper['skill']!))), icon: const Icon(Icons.chat), label: Text("Chat with ${corper['name']}"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: OutlinedButton.icon(onPressed: ()=>openWhatsAppDirect(corper['phone']!, "Hello ${corper['name']}, I saw your profile on Naija Copas Connect"), icon: const Icon(Icons.message), label: const Text("WhatsApp"))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: ()=>openCall(corper['phone']!), icon: const Icon(Icons.call), label: const Text("Call")))]),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: ()=>openVideoCall(corper['name']!), icon: const Icon(Icons.videocam), label: const Text("Video Call")),
      ]),
    );
  }
}

class ChatDetailScreen extends StatefulWidget { final String corperName, corperSkill; const ChatDetailScreen({super.key, required this.corperName, required this.corperSkill}); @override State<ChatDetailScreen> createState() => _ChatDetailScreenState(); }
class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final List<Map<String,String>> messages = [];
  void send(){ if(_ctrl.text.trim().isEmpty) return; setState(()=>messages.insert(0, {"text":_ctrl.text.trim(), "isMe":"true"})); _ctrl.clear(); }
  @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: Text(widget.corperName), backgroundColor: Colors.green[700], foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.videocam), onPressed: ()=>openVideoCall(widget.corperName))]), body: Column(children: [Expanded(child: messages.isEmpty? Center(child: Text("Start chatting with ${widget.corperName} 👋")) : ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: messages.length, itemBuilder: (c,i){ final m=messages[i]; final isMe=m["isMe"]=="true"; return Align(alignment: isMe? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe? Colors.green[700]: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text(m["text"]!, style: TextStyle(color: isMe? Colors.white: Colors.black)))); })), Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Row(children: [Expanded(child: TextField(controller: _ctrl, onSubmitted: (_)=>send(), decoration: InputDecoration(hintText: "Type message...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)))), const SizedBox(width: 8), CircleAvatar(backgroundColor: Colors.green[700], child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: send))]))])); }
}

// JOBS TAB - FULLY FIXED
class JobsTab extends StatefulWidget { const JobsTab({super.key}); @override State<JobsTab> createState() => _JobsTabState(); }
class _JobsTabState extends State<JobsTab> {
  List<Map<String,String>> jobs = [];
  String myName = "You";
  @override void initState(){ super.initState(); loadJobs(); loadMyName(); }
  Future<void> loadMyName() async { final sp = await SharedPreferences.getInstance(); setState(()=> myName = sp.getString('name')?? "You"); }
  Future<void> loadJobs() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString('jobs_list');
    if(saved!=null){ try{ final List list = jsonDecode(saved); setState(()=> jobs = list.map((e)=> Map<String,String>.from(e)).toList()); }catch(_){} }
    if(jobs.isEmpty){ setState(()=> jobs = [{"title":"Home Lesson Teacher", "pay":"₦20k/month", "location":"Ibadan - Bodija", "desc":"Teach JSS2 Maths 3x weekly", "contact":"08012345678", "postedBy":"Emeka D."}]); }
  }
  Future<void> saveJobs() async { final sp = await SharedPreferences.getInstance(); await sp.setString('jobs_list', jsonEncode(jobs)); }
  void addJobDialog(){
    final t=TextEditingController(); final p=TextEditingController(); final l=TextEditingController(); final d=TextEditingController(); final c=TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(
      title: const Text("Post a Job"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: t, decoration: const InputDecoration(labelText: "Job Title *")),
        TextField(controller: p, decoration: const InputDecoration(labelText: "Pay e.g ₦20k/month")),
        TextField(controller: l, decoration: const InputDecoration(labelText: "Location e.g Bodija")),
        TextField(controller: c, decoration: const InputDecoration(labelText: "Your WhatsApp Number *", hintText: "08012345678"), keyboardType: TextInputType.phone),
        TextField(controller: d, deco
