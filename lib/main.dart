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
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {}
    }
  } catch (_) {}
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
  final List<Widget> screens = const [
    ConnectTab(),
    JobsTab(),
    LodgesTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(const ["Naija Copas Connect", "Naija Jobs", "Corper Lodge", "Profile"][0]),
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

Future<void> openWhatsAppDirect(String phone, String msg) async {
  String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleanPhone.startsWith('0')) cleanPhone = '234${cleanPhone.substring(1)}';
  final url = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}");
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    try {
      await launchUrl(Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msg)}"),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

Future<void> openCall(String phone) async {
  try {
    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse("tel:$clean"));
  } catch (_) {}
}

Future<void> openVideoCall(String room) async {
  try {
    await launchUrl(
      Uri.parse("https://meet.jit.si/${room.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_NaijaCopas"),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {}
}

void showPosterProfile(BuildContext context, Map<String, String> item, bool isJob) {
  String postedBy = item['postedBy']?? 'Corper';
  String contact = item['contact']?? '';
  String location = isJob? (item['location']?? '') : (item['area']?? '');
  String title = isJob? (item['title']?? '') : (item['area']?? '');
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            CircleAvatar(radius: 40, backgroundColor: Colors.green[100], child: Text(postedBy[0].toUpperCase(), style: TextStyle(fontSize: 30, color: Colors.green[700], fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Text(postedBy, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Posted $title", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
            Card(child: ListTile(leading: Icon(Icons.location_on, color: Colors.green[700]), title: const Text("Location"), subtitle: Text(location))),
            Card(child: ListTile(leading: Icon(Icons.phone, color: Colors.green[700]), title: const Text("WhatsApp"), subtitle: Text(contact))),
            Card(child: ListTile(leading: Icon(Icons.verified, color: Colors.green[700]), title: const Text("Verified Corper"), subtitle: const Text("NYSC Member"))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: () { Navigator.pop(ctx); openWhatsAppDirect(contact, isJob? "Hello $postedBy, I saw your job $title on Naija Copas Connect" : "Hello $postedBy, lodge at $title on Naija Copas Connect"); }, icon: const Icon(Icons.chat), label: Text("Chat with $postedBy"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white))),
          ],
        ),
      );
    },
  );
}

// CONNECT TAB
class ConnectTab extends StatefulWidget { const ConnectTab({super.key}); @override State<ConnectTab> createState() => _ConnectTabState(); }
class _ConnectTabState extends State<ConnectTab> {
  String search = "";
  final corpers = [
    {'name': 'Emeka D.', 'state': 'Oyo - Ibadan', 'ppa': 'UI Secondary School', 'skill': 'Tutoring, Maths', 'batch': 'Batch C 2025', 'about': 'NYSC Corper at UI. Maths/Physics tutor.', 'phone': '08012345678'},
    {'name': 'Chioma D.', 'state': 'Lagos - Ikeja', 'ppa': 'Tech Startup, Yaba', 'skill': 'Graphics Design', 'batch': 'Batch B 2025', 'about': 'Creative designer for corpers.', 'phone': '08023456789'},
    {'name': 'Aisha B.', 'state': 'Abuja', 'ppa': 'Ministry of Education', 'skill': 'Makeup, Gele', 'batch': 'Batch C 2025', 'about': 'Professional makeup artist.', 'phone': '08034567890'},
  ];

  Future<void> createPostDialog() async {
    final textCtrl = TextEditingController();
    final sp = await SharedPreferences.getInstance();
    String myName = sp.getString('name')?? 'Yunus Eunice';
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("New Post"),
      content: TextField(controller: textCtrl, maxLines: 3, decoration: const InputDecoration(hintText: "Hello Oyo people...")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          if (textCtrl.text.trim().isEmpty) return;
          await FirebaseFirestore.instance.collection('posts').add({
            'text': textCtrl.text.trim(),
            'state': 'Oyo',
            'uid': FirebaseAuth.instance.currentUser?.uid?? 'test123',
            'userName': myName,
            'likeCount': 0,
            'commentCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          if (mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post"))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = corpers.where((c) => c['name']!.toLowerCase().contains(search.toLowerCase()) || c['skill']!.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: createPostDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v) => setState(() => search = v), decoration: InputDecoration(hintText: "Search name, skill...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(), builder: (context, snap) {
          if (snap.hasError) return Padding(padding: const EdgeInsets.all(8), child: Text("Feed error: ${snap.error}", style: const TextStyle(fontSize: 11, color: Colors.red)));
          if (!snap.hasData) return const SizedBox();
          if (snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text("No posts yet. Tap + to post", style: TextStyle(fontSize: 12)));
          var docs = snap.data!.docs;
          return SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: docs.length, padding: const EdgeInsets.symmetric(horizontal: 12), itemBuilder: (ctx, i) {
            var d = docs[i].data() as Map<String, dynamic>;
            return Container(width: 240, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['userName']?? 'Corper', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 4), Text(d['text']?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)), const Spacer(), Text(d['state']?? 'Oyo', style: TextStyle(fontSize: 10, color: Colors.grey[600]))]));
          }));
        }),
        const Divider(height: 1),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (ctx, i) { final c = filtered[i]; return Card(child: ListTile(title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${c['state']} • ${c['skill']}"), trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(corperName: c['name']!, corperSkill: c['skill']!))), child: const Text("Chat")))); }))
      ]),
    );
  }
}

class ChatDetailScreen extends StatefulWidget { final String corperName, corperSkill; const ChatDetailScreen({super.key, required this.corperName, required this.corperSkill}); @override State<ChatDetailScreen> createState() => _ChatDetailScreenState(); }
class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final List<Map<String,String>> messages = [];
  void send(){ if(_ctrl.text.trim().isEmpty) return; setState(()=>messages.insert(0, {"text":_ctrl.text.trim(), "isMe":"true"})); _ctrl.clear(); }
  @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: Text(widget.corperName), backgroundColor: Colors.green[700], foregroundColor: Colors.white), body: Column(children: [Expanded(child: messages.isEmpty? Center(child: Text("Start chatting with ${widget.corperName}")) : ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: messages.length, itemBuilder: (c,i){ final m=messages[i]; final isMe=m["isMe"]=="true"; return Align(alignment: isMe? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe? Colors.green[700]: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text(m["text"]!, style: TextStyle(color: isMe? Colors.white: Colors.black)))); })), Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Row(children: [Expanded(child: TextField(controller: _ctrl, onSubmitted: (_)=>send(), decoration: InputDecoration(hintText: "Type message...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)))), const SizedBox(width: 8), CircleAvatar(backgroundColor: Colors.green[700], child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: send))]))])); }
}

// JOBS TAB
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
        TextField(controller: d, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: (){
          if(t.text.trim().isEmpty || c.text.trim().isEmpty) return;
          setState(()=> jobs.insert(0, {"title": t.text.trim(), "pay": p.text.trim(), "location": l.text.trim(), "desc": d.text.trim(), "contact": c.text.trim(), "postedBy": myName}));
          saveJobs();
          Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post Job"))
      ],
    ));
  }
  @override Widget build(BuildContext context){
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: addJobDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)),
      body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: jobs.length, itemBuilder: (ctx,i){
        final j = jobs[i];
        return Card(child: ListTile(title: Text(j['title']??'', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${j['pay']} • ${j['location']}\n${j['desc']}"), isThreeLine: true, onTap: ()=> showPosterProfile(context, j, true), trailing: IconButton(icon: Icon(Icons.chat, color: Colors.green[700]), onPressed: ()=> openWhatsAppDirect(j['contact']??'', "Hello, I saw your job ${j['title']} on Naija Copas Connect"))));
      }),
    );
  }
}

// LODGES TAB
class LodgesTab extends StatefulWidget { const LodgesTab({super.key}); @override State<LodgesTab> createState() => _LodgesTabState(); }
class _LodgesTabState extends State<LodgesTab> {
  List<Map<String,String>> lodges = [];
  String myName = "You";
  @override void initState(){ super.initState(); loadLodges(); loadMyName(); }
  Future<void> loadMyName() async { final sp = await SharedPreferences.getInstance(); setState(()=> myName = sp.getString('name')?? "You"); }
  Future<void> loadLodges() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString('lodges_list');
    if(saved!=null){ try{ final List list = jsonDecode(saved); setState(()=> lodges = list.map((e)=> Map<String,String>.from(e)).toList()); }catch(_){} }
    if(lodges.isEmpty){ setState(()=> lodges = [{"area":"Bodija - UI Area", "price":"₦150k/year", "type":"Self-con", "desc":"Water, light, close to UI", "contact":"08087654321", "postedBy":"Chioma D."}]); }
  }
  Future<void> saveLodges() async { final sp = await SharedPreferences.getInstance(); await sp.setString('lodges_list', jsonEncode(lodges)); }
  void addLodgeDialog(){
    final a=TextEditingController(); final pr=TextEditingController(); final ty=TextEditingController(); final de=TextEditingController(); final co=TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(
      title: const Text("Post a Lodge"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: a, decoration: const InputDecoration(labelText: "Area * e.g Bodija")),
        TextField(controller: pr, decoration: const InputDecoration(labelText: "Price * e.g ₦150k/year")),
        TextField(controller: ty, decoration: const InputDecoration(labelText: "Type e.g Self-con")),
        TextField(controller: co, decoration: const InputDecoration(labelText: "WhatsApp Number *"), keyboardType: TextInputType.phone),
        TextField(controller: de, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: (){
          if(a.text.trim().isEmpty || co.text.trim().isEmpty) return;
          setState(()=> lodges.insert(0, {"area": a.text.trim(), "price": pr.text.trim(), "type": ty.text.trim(), "desc": de.text.trim(), "contact": co.text.trim(), "postedBy": myName}));
          saveLodges();
          Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post Lodge"))
      ],
    ));
  }
  @override Widget build(BuildContext context){
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: addLodgeDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)),
      body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: lodges.length, itemBuilder: (ctx,i){
        final lg = lodges[i];
        return Card(child: ListTile(title: Text(lg['area']??'', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${lg['price']} • ${lg['type']}\n${lg['desc']}"), isThreeLine: true, onTap: ()=> showPosterProfile(context, lg, false), trailing: IconButton(icon: Icon(Icons.chat, color: Colors.green[700]), onPressed: ()=> openWhatsAppDirect(lg['contact']??'', "Hello, lodge at ${lg['area']}"))));
      }),
    );
  }
}

// PROFILE TAB - FIXED CONSTRUCTOR
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override Widget build(BuildContext context) {
    return _ProfileTabContent();
  }
}

class _ProfileTabContent extends StatefulWidget { const _ProfileTabContent(); @override
