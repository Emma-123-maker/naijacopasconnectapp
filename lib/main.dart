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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final List<Widget> screens = [
    ConnectTab(),
    JobsTab(),
    LodgesTab(),
    ProfileTab(),
  ];
  final List<String> titles = [
    "Naija Copas Connect",
    "Naija Jobs",
    "Corper Lodge",
    "Profile"
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
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
  if (clean.startsWith('0')) {
    clean = '234${clean.substring(1)}';
  }
  final url = Uri.parse("https://wa.me/$clean?text=${Uri.encodeComponent(msg)}");
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

// CONNECT TAB WITH NEWS FEED
class ConnectTab extends StatefulWidget {
  ConnectTab({super.key});
  @override
  State<ConnectTab> createState() => _ConnectTabState();
}

class _ConnectTabState extends State<ConnectTab> {
  String search = "";
  final List<Map<String, String>> corpers = [
    {'name': 'Emeka D.', 'state': 'Oyo - Ibadan', 'ppa': 'UI Sec School', 'skill': 'Tutoring, Maths', 'batch': 'Batch C 2025', 'phone': '08012345678'},
    {'name': 'Chioma D.', 'state': 'Lagos - Ikeja', 'ppa': 'Tech Startup', 'skill': 'Graphics Design', 'batch': 'Batch B 2025', 'phone': '08023456789'},
    {'name': 'Aisha B.', 'state': 'Abuja', 'ppa': 'Ministry of Education', 'skill': 'Makeup, Gele', 'batch': 'Batch C 2025', 'phone': '08034567890'},
  ];

  Future<void> createPostDialog() async {
    final textCtrl = TextEditingController();
    final sp = await SharedPreferences.getInstance();
    String myName = sp.getString('name')?? 'Yunus Eunice';
    String myState = sp.getString('stateBatch')?? 'Oyo State';
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create Post"),
        content: TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: "What's happening in your PPA?")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = corpers.where((c) => c['name']!.toLowerCase().contains(search.toLowerCase()) || c['skill']!.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createPostDialog,
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Post Feed", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Corper Feed", style: TextStyle(fontWeight: FontWeight.bold)),
                    InkWell(onTap: createPostDialog, child: Text("Post gist", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).limit(10).snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) return const Text("Feed offline - check Firestore rules", style: TextStyle(fontSize: 11));
                    if (!snap.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                    if (snap.data!.docs.isEmpty) return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)), child: const Text("No gist yet. Be the first! 🎉", style: TextStyle(fontSize: 12)));
                    var docs = snap.data!.docs;
                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          var d = docs[i].data() as Map<String, dynamic>;
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF9F5F3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['userName']?? 'Corper', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 4),
                              Expanded(child: Text(d['text']?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                              Text(d['state']?? 'Oyo', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            ]),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(hintText: "Search name, skill...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final c = filtered[i];
                return Card(child: ListTile(title: Text(c['name']!), subtitle: Text("${c['state']} - ${c['skill']}"), trailing: ElevatedButton(onPressed: () => openWhatsAppDirect(c['phone']!, "Hello ${c['name']}"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Chat"))));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class JobsTab extends StatefulWidget { const JobsTab({super.key}); @override State<JobsTab> createState() => _JobsTabState(); }
class _JobsTabState extends State<JobsTab> {
  List<Map<String, String>> jobs = [{"title": "Home Lesson Teacher", "pay": "₦20k/month", "location": "Ibadan - Bodija", "desc": "Teach JSS2 Maths", "contact": "08012345678", "postedBy": "Emeka D."}];
  Future<void> loadJobs() async { final sp = await SharedPreferences.getInstance(); final s = sp.getString('jobs_list'); if (s!= null) { try { final List l = jsonDecode(s); setState(() => jobs = l.map((e) => Map<String, String>.from(e)).toList()); } catch (_) {} } }
  Future<void> saveJobs() async { final sp = await SharedPreferences.getInstance(); await sp.setString('jobs_list', jsonEncode(jobs)); }
  @override void initState() { super.initState(); loadJobs(); }
  void addJobDialog() {
    final t = TextEditingController(); final p = TextEditingController(); final l = TextEditingController(); final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Post a Job"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: "Job Title *")), TextField(controller: p, decoration: const InputDecoration(labelText: "Pay")), TextField(controller: l, decoration: const InputDecoration(labelText: "Location")), TextField(controller: c, decoration: const InputDecoration(labelText: "WhatsApp *"))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () { if (t.text.isEmpty || c.text.isEmpty) return; setState(() => jobs.insert(0, {"title": t.text, "pay": p.text, "location": l.text, "desc": "", "contact": c.text, "postedBy": "You"})); saveJobs(); Navigator.pop(ctx); }, child: const Text("Post"))]));
  }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton(onPressed: addJobDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)), body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: jobs.length, itemBuilder: (ctx, i) { final j = jobs[i]; return Card(child: ListTile(title: Text(j['title']!), subtitle: Text("${j['pay']} - ${j['location']}"))); })); }
}

class LodgesTab extends StatefulWidget { const LodgesTab({super.key}); @override State<LodgesTab> createState() => _LodgesTabState(); }
class _LodgesTabState extends State<LodgesTab> {
  List<Map<String, String>> lodges = [{"area": "Bodija - UI", "price": "₦150k/year", "type": "Self-con", "desc": "Water, light", "contact": "08087654321", "postedBy": "Chioma D."}];
  Future<void> loadLodges() async { final sp = await SharedPreferences.getInstance(); final s = sp.getString('lodges_list'); if (s!= null) { try { final List l = jsonDecode(s); setState(() => lodges = l.map((e) => Map<String, String>.from(e)).toList()); } catch (_) {} } }
  Future<void> saveLodges() async { final sp = await SharedPreferences.getInstance(); await sp.setString('lodges_list', jsonEncode(lodges)); }
  @override void initState() { super.initState(); loadLodges(); }
  void addLodgeDialog() {
    final a = TextEditingController(); final pr = TextEditingController(); final co = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Post a Lodge"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: a, decoration: const InputDecoration(labelText: "Area *")), TextField(controller: pr, decoration: const InputDecoration(labelText: "Price *")), TextField(controller: co, decoration: const InputDecoration(labelText: "WhatsApp *"))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () { if (a.text.isEmpty || co.text.isEmpty) return; setState(() => lodges.insert(0, {"area": a.text, "price": pr.text, "type": "", "desc": "", "contact": co.text, "postedBy": "You"})); saveLodges(); Navigator.pop(ctx); }, child: const Text("Post"))]));
  }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton(onPressed: addLodgeDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)), body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: lodges.length, itemBuilder: (ctx, i) { final lg = lodges[i]; return Card(child: ListTile(title: Text(lg['area']!), subtitle: Text(lg['price']!))); })); }
}

// FIXED PROFILE TAB - NO MISSING BRACE
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String name = "Yunus Eunice";
  String stateBatch = "Oyo State - Batch C 2025";
  String ppa = "Community Secondary School, Ibadan";
  String skills = "Tutoring, Makeup, Baking";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      name = sp.getString('name')?? name;
      stateBatch = sp.getString('stateBatch')?? stateBatch;
      ppa = sp.getString('ppa')?? ppa;
      skills = sp.getString('skills')?? skills;
    });
  }

  Future<void> saveProfile(String n, String sb, String p, String sk) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('name', n);
    await sp.setString('stateBatch', sb);
    await sp.setString('ppa', p);
    await sp.setString('skills', sk);
    setState(() {
      name = n;
      stateBatch = sb;
      ppa = p;
      skills = sk;
    });
  }

  void editDialog() {
    final nCtrl = TextEditingController(text: name);
    final sbCtrl = TextEditingController(text: stateBatch);
    final pCtrl = TextEditingController(text: ppa);
    final skCtrl = TextEditingController(text: skills);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nCtrl, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: sbCtrl, decoration: const InputDecoration(labelText: "State - Batch")),
              TextField(controller: pCtrl, decoration: const InputDecoration(labelText: "PPA")),
              TextField(controller: skCtrl, decoration: const InputDecoration(labelText: "Skills")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              saveProfile(nCtrl.text, sbCtrl.text, pCtrl.text, skCtrl.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          Center(child: CircleAvatar(radius: 50, backgroundColor: Colors.green[100], child: Text(name.isNotEmpty? name[0].toUpperCase() : "Y", style: TextStyle(fontSize: 40, color: Colors.green[700], fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
          Center(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          Center(child: Text(stateBatch, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.school, color: Colors.green[700]), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("PPA", style: TextStyle(fontWeight: FontWeight.bold)), Text(ppa)])) ])),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.star, color: Colors.green[700]), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Skills", style: TextStyle(fontWeight: FontWeight.bold)), Text(skills)])) ])),
          const SizedBox(height: 20),
          SizedBox(height: 48, child: ElevatedButton.icon(onPressed: editDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("Edit Profile"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ],
      ),
    );
  }
}
