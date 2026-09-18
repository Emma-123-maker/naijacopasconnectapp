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
      await FirebaseAuth.instance.signInAnonymously();
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
        scaffoldBackgroundColor: const Color(0xFFF9F5F3),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final List<Widget> screens = [ConnectTab(), JobsTab(), LodgesTab(), ProfileTab()];
  final titles = ["Naija Copas Connect", "Naija Jobs", "Corper Lodge", "Profile"];
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[currentIndex]), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
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

Future<void> openWhatsAppDirect(String phone, String msg) async {
  String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.startsWith('0')) clean = '234${clean.substring(1)}';
  final url = Uri.parse("https://wa.me/$clean?text=${Uri.encodeComponent(msg)}");
  try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (_) {}
}

// CONNECT TAB WITH NEWS FEED ADDED
class ConnectTab extends StatefulWidget { ConnectTab({super.key}); @override State<ConnectTab> createState() => _ConnectTabState(); }
class _ConnectTabState extends State<ConnectTab> {
  String search = "";
  final corpers = [
    {'name': 'Emeka D.', 'state': 'Oyo - Ibadan', 'ppa': 'Community Secondary School, Ibadan', 'skill': 'Tutoring, Maths', 'batch': 'Batch C 2025', 'about': 'NYSC Corper teaching Maths and Physics', 'phone': '08012345678'},
    {'name': 'Chioma D.', 'state': 'Lagos - Ikeja', 'ppa': 'Tech Startup, Yaba', 'skill': 'Graphics Design, Branding', 'batch': 'Batch B 2025', 'about': 'Designer for corpers', 'phone': '08023456789'},
    {'name': 'Aisha B.', 'state': 'Abuja', 'ppa': 'Ministry of Education', 'skill': 'Makeup, Gele', 'batch': 'Batch C 2025', 'about': 'Makeup artist', 'phone': '08034567890'},
    {'name': 'Tunde O.', 'state': 'Oyo - Ogbomoso', 'ppa': 'LAUTECH', 'skill': 'Web Dev, Flutter', 'batch': 'Batch A 2025', 'about': 'Flutter dev', 'phone': '08045678901'},
  ];

  Future<void> createPostDialog() async {
    final textCtrl = TextEditingController();
    final sp = await SharedPreferences.getInstance();
    String myName = sp.getString('name')?? 'Yunus Eunice';
    String myState = sp.getString('state')?? 'Oyo State';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Create Post"),
      content: TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: "What's happening in your PPA? Share gist...")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          if (textCtrl.text.trim().isEmpty) return;
          try {
            await FirebaseFirestore.instance.collection('posts').add({
              'text': textCtrl.text.trim(),
              'state': myState,
              'uid': FirebaseAuth.instance.currentUser?.uid?? 'anon',
              'userName': myName,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
          if (mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post")),
      ],
    ));
  }

  @override Widget build(BuildContext context) {
    final filtered = corpers.where((c) => c['name']!.toLowerCase().contains(search.toLowerCase()) || c['skill']!.toLowerCase().contains(search.toLowerCase()) || c['state']!.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton.extended(onPressed: createPostDialog, backgroundColor: Colors.green[700], icon: const Icon(Icons.add, color: Colors.white), label: const Text("Post Feed", style: TextStyle(color: Colors.white))),
      body: Column(children: [
        // NEWS FEED SECTION - NEW
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Corper Feed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              InkWell(onTap: createPostDialog, child: Text("Post gist", style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).limit(10).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return const Text("Feed offline", style: TextStyle(fontSize: 11));
                if (!snap.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                if (snap.data!.docs.isEmpty) return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)), child: const Text("No gist yet. Be the first to post! 🎉", style: TextStyle(fontSize: 12)));
                var docs = snap.data!.docs;
                return SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: docs.length, itemBuilder: (ctx, i) {
                  var d = docs[i].data() as Map<String, dynamic>;
                  return Container(width: 220, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF9F5F3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['userName']?? 'Corper', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    Expanded(child: Text(d['text']?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                    Text(d['state']?? 'Oyo', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ]));
                }));
              },
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: TextField(onChanged: (v) => setState(() => search = v), decoration: InputDecoration(hintText: "Search name, skill, state...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        const SizedBox(height: 8),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: filtered.length, itemBuilder: (ctx, i) {
          final c = filtered[i];
          return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]), child: ListTile(
            leading: CircleAvatar(radius: 24, backgroundColor: Colors.green[100], child: Text(c['name']![0], style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold))),
            title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${c['state']} • ${c['batch']}", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)), child: Text(c['skill']!, style: TextStyle(fontSize: 11, color: Colors.green[700]))),
              const SizedBox(height: 2),
              Text("Tap to view full profile", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ]),
            trailing: ElevatedButton(onPressed: () => openWhatsAppDirect(c['phone']!, "Hello ${c['name']}, I saw you on Naija Copas Connect"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, minimumSize: const Size(60, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("Chat", style: TextStyle(fontSize: 12))),
            onTap: () {},
          ));
        })),
      ]),
    );
  }
}

// JOBS TAB - SAME DESIGN AS SCREENSHOT
class JobsTab extends StatefulWidget { const JobsTab({super.key}); @override State<JobsTab> createState() => _JobsTabState(); }
class _JobsTabState extends State<JobsTab> {
  List<Map<String,String>> jobs = [{"title":"Home Lesson Teacher","pay":"₦20k/month","location":"Ibadan - Bodija","desc":"Teach JSS2 Maths 3x weekly","contact":"08012345678","postedBy":"Emeka D."}];
  @override void initState(){ super.initState(); loadJobs(); }
  Future<void> loadJobs() async { final sp = await SharedPreferences.getInstance(); final s = sp.getString('jobs_list'); if(s!=null){ try{ final List l=jsonDecode(s); setState(()=>jobs=l.map((e)=>Map<String,String>.from(e)).toList()); }catch(_){} } }
  Future<void> saveJobs() async { final sp = await SharedPreferences.getInstance(); await sp.setString('jobs_list', jsonEncode(jobs)); }
  void addJobDialog(){
    final t=TextEditingController(); final p=TextEditingController(); final l=TextEditingController(); final d=TextEditingController(); final c=TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(title: const Text("Post a Job"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: "Job Title *")), TextField(controller: p, decoration: const InputDecoration(labelText: "Pay e.g ₦20k/month")), TextField(controller: l, decoration: const InputDecoration(labelText: "Location")), TextField(controller: c, decoration: const InputDecoration(labelText: "Contact WhatsApp *"), keyboardType: TextInputType.phone), TextField(controller: d, decoration: const InputDecoration(labelText: "Description"), maxLines: 2)])), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: (){ if(t.text.isEmpty||c.text.isEmpty) return; setState(()=>jobs.insert(0, {"title":t.text.trim(),"pay":p.text.trim(),"location":l.text.trim(),"desc":d.text.trim(),"contact":c.text.trim(),"postedBy":"You"})); saveJobs(); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post"))]));
  }
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton.extended(onPressed: addJobDialog, backgroundColor: Colors.green[700], icon: const Icon(Icons.add, color: Colors.white), label: const Text("Post Job", style: TextStyle(color: Colors.white))), body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: jobs.length, itemBuilder: (ctx,i){ final j=jobs[i]; return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(j['title']!, style: const TextStyle(fontWeight: FontWeight.bold)), Text(j['pay']!, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12))]), const SizedBox(height: 6), Row(children: [CircleAvatar(radius: 10, backgroundColor: Colors.green[50], child: Text(j['postedBy']![0], style: TextStyle(fontSize: 10, color: Colors.green[700]))), const SizedBox(width: 6), Text("Posted by ${j['postedBy']} • ${j['location']}", style: TextStyle(fontSize: 11, color: Colors.grey[600]))]), const SizedBox(height: 8), Text(j['desc']!, style: const TextStyle(fontSize: 13)), const SizedBox(height: 4), Text("Contact: ${j['contact']}", style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.bold)), const SizedBox(height: 10), Row(children: [Expanded(child: ElevatedButton.icon(onPressed: ()=>openWhatsAppDirect(j['contact']!, "Hello, I saw your job ${j['title']} on Naija Copas Connect. Is it still available?"), icon: const Icon(Icons.send, size: 16), label: const Text("Apply via WhatsApp"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))), IconButton(onPressed: (){ setState(()=>jobs.removeAt(i)); saveJobs(); }, icon: const Icon(Icons.delete, color: Colors.red))])])); }));
  }
}

class LodgesTab extends StatefulWidget { const LodgesTab({super.key}); @override State<LodgesTab> createState() => _LodgesTabState(); }
class _LodgesTabState extends State<LodgesTab> {
  List<Map<String,String>> lodges = [{"area":"Agbowo, UI","price":"₦120k/year","type":"Self-con, water, light, 2 corpers needed. Close to campus.","desc":"Close to campus","contact":"08012345678","postedBy":"Chioma D."}];
  @override void initState(){ super.initState(); loadLodges(); }
  Future<void> loadLodges() async { final sp = await SharedPreferences.getInstance(); final s = sp.getString('lodges_list'); if(s!=null){ try{ final List l=jsonDecode(s); setState(()=>lodges=l.map((e)=>Map<String,String>.from(e)).toList()); }catch(_){} } }
  Future<void> saveLodges() async { final sp = await SharedPreferences.getInstance(); await sp.setString('lodges_list', jsonEncode(lodges)); }
  void addLodgeDialog(){
    final a=TextEditingController(); final pr=TextEditingController(); final de=TextEditingController(); final co=TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(title: const Text("Post a Lodge"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: a, decoration: const InputDecoration(labelText: "Area e.g Agbowo, UI *")), TextField(controller: pr, decoration: const InputDecoration(labelText: "Price e.g ₦120k/year")), TextField(controller: de, decoration: const InputDecoration(labelText: "Details")), TextField(controller: co, decoration: const InputDecoration(labelText: "Contact *"), keyboardType: TextInputType.phone)])), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: (){ if(a.text.isEmpty||co.text.isEmpty) return; setState(()=>lodges.insert(0, {"area":a.text.trim(),"price":pr.text.trim(),"type":de.text.trim(),"desc":de.text.trim(),"contact":co.text.trim(),"postedBy":"You"})); saveLodges(); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post"))]));
  }
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton.extended(onPressed: addLodgeDialog, backgroundColor: Colors.green[700], icon: const Icon(Icons.add, color: Colors.white), label: const Text("Post Lodge", style: TextStyle(color: Colors.white))), body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: lodges.length, itemBuilder: (ctx,i){ final lg=lodges[i]; return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(lg['area']!, style: const TextStyle(fontWeight: FontWeight.bold)), Text(lg['price']!, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12))]), const SizedBox(height: 6), Text("Posted by ${lg['postedBy']}", style: TextStyle(fontSize: 11, color: Colors.grey[600])), const SizedBox(height: 8), Text(lg['type']!, style: const TextStyle(fontSize: 13)), const SizedBox(height: 4), Text("Contact: ${lg['contact']}", style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.bold)), const SizedBox(height: 10), Row(children: [Expanded(child: ElevatedButton.icon(onPressed: ()=>openWhatsAppDirect(lg['contact']!, "Hello, I'm interested in lodge at ${lg['area']} on Naija Copas Connect"), icon: const Icon(Icons.chat_bubble, size: 16), label: const Text("Contact on WhatsApp"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))), IconButton(onPressed: (){ setState(()=>lodges.removeAt(i)); saveLodges(); }, icon: const Icon(Icons.delete, color: Colors.red))])])); }));
  }
}

class ProfileTab extends StatefulWidget { const ProfileTab({super.key}); @override State<ProfileTab> createState() => _ProfileTabState(); }
class _ProfileTabState extends State<ProfileTab> {
  String name = "Yunus Eunice"; String stateBatch = "Oyo State • Batch C 2025"; String ppa = "Community Secondary School, Ibadan"; String skills = "Tutoring, Makeup, Baking";
  @override void initState(){ super.initState(); load(); }
  Future<void> load() async { final sp = await SharedPreferences.getInstance(); setState((){ name = sp.getString('name')?? name; stateBatch = sp.getString('stateBatch')?? stateBatch; ppa = sp.getString('ppa')?? ppa; skills = sp.getString('skills')?? skills; }); }
  Future<void> saveData(String n, String sb, String p, String sk) async { final sp = await SharedPreferences.getInstance(); await sp.setString('name', n); await sp.setString('stateBatch', sb); await sp.setString('ppa', p); await sp.setString('skills', sk); setState((){ name=n; stateBatch=sb; ppa=p; skills=sk; }); }
  void editDialog(){
    final n=TextEditingController(text: name); 
