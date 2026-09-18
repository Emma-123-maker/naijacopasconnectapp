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
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
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

  List<String> titles = [
    "Naija Copas Connect",
    "Naija Jobs",
    "Corper Lodge",
    "Profile"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[currentIndex]), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
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
  String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.startsWith('0')) clean = '234${clean.substring(1)}';
  final url = Uri.parse("https://wa.me/$clean?text=${Uri.encodeComponent(msg)}");
  try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (_) {}
}
Future<void> openCall(String phone) async {
  try { await launchUrl(Uri.parse("tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}")); } catch (_) {}
}
Future<void> openVideoCall(String room) async {
  try { await launchUrl(Uri.parse("https://meet.jit.si/${room.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}"), mode: LaunchMode.externalApplication); } catch (_) {}
}

void showPosterProfile(BuildContext context, Map<String, String> item, bool isJob) {
  String postedBy = item['postedBy']?? 'Corper';
  String contact = item['contact']?? '';
  String location = isJob? (item['location']?? '') : (item['area']?? '');
  String title = isJob? (item['title']?? '') : (item['area']?? '');
  showModalBottomSheet(context: context, builder: (ctx) {
    return Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(postedBy, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text("Posted $title"),
      const SizedBox(height: 10),
      ListTile(leading: const Icon(Icons.location_on), title: Text(location)),
      ListTile(leading: const Icon(Icons.phone), title: Text(contact)),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); openWhatsAppDirect(contact, "Hello $postedBy, I saw your $title on Naija Copas Connect"); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Chat on WhatsApp"))),
    ]));
  });
}

class ConnectTab extends StatefulWidget { const ConnectTab({super.key}); @override State<ConnectTab> createState() => _ConnectTabState(); }
class _ConnectTabState extends State<ConnectTab> {
  String search = "";
  final corpers = [
    {'name': 'Emeka D.', 'state': 'Oyo - Ibadan', 'ppa': 'UI Sec School', 'skill': 'Tutoring, Maths', 'batch': 'Batch C 2025', 'about': 'Maths tutor', 'phone': '08012345678'},
    {'name': 'Chioma D.', 'state': 'Lagos - Ikeja', 'ppa': 'Tech Startup', 'skill': 'Graphics Design', 'batch': 'Batch B 2025', 'about': 'Designer', 'phone': '08023456789'},
  ];
  Future<void> createPostDialog() async {
    final textCtrl = TextEditingController();
    final sp = await SharedPreferences.getInstance();
    String myName = sp.getString('name')?? 'Yunus Eunice';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("New Post"),
      content: TextField(controller: textCtrl, maxLines: 3, decoration: const InputDecoration(hintText: "Hello Oyo people...")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          if (textCtrl.text.trim().isEmpty) return;
          try {
            await FirebaseFirestore.instance.collection('posts').add({
              'text': textCtrl.text.trim(),
              'state': 'Oyo',
              'uid': FirebaseAuth.instance.currentUser?.uid?? 'anon',
              'userName': myName,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
          if (mounted) Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post"))
      ],
    ));
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: createPostDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)),
      body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: corpers.length, itemBuilder: (ctx, i) {
        final c = corpers[i];
        return Card(child: ListTile(title: Text(c['name']!), subtitle: Text("${c['state']} - ${c['skill']}"), trailing: const Icon(Icons.chat)));
      }),
    );
  }
}

class JobsTab extends StatefulWidget { const JobsTab({super.key}); @override State<JobsTab> createState() => _JobsTabState(); }
class _JobsTabState extends State<JobsTab> {
  List<Map<String,String>> jobs = [{"title":"Home Lesson Teacher","pay":"₦20k/month","location":"Ibadan - Bodija","desc":"Teach JSS2 Maths","contact":"08012345678","postedBy":"Emeka D."}];
  void addJobDialog(){
    final t=TextEditingController(); final p=TextEditingController(); final l=TextEditingController(); final c=TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(
      title: const Text("Post a Job"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: t, decoration: const InputDecoration(labelText: "Job Title *")),
        TextField(controller: p, decoration: const InputDecoration(labelText: "Pay")),
        TextField(controller: l, decoration: const InputDecoration(labelText: "Location")),
        TextField(controller: c, decoration: const InputDecoration(labelText: "WhatsApp *")),
      ]),
      actions: [ TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: (){ if(t.text.isEmpty||c.text.isEmpty) return; setState(()=>jobs.insert(0, {"title":t.text,"pay":p.text,"location":l.text,"desc":"","contact":c.text,"postedBy":"You"})); Navigator.pop(ctx); }, child: const Text("Post")) ],
    ));
  }
  @override Widget build(BuildContext context){ return Scaffold(floatingActionButton: FloatingActionButton(onPressed: addJobDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)), body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: jobs.length, itemBuilder: (ctx,i){ final j=jobs[i]; return Card(child: ListTile(title: Text(j['title']!), subtitle: Text("${j['pay']} - ${j['location']}"), onTap: ()=>showPosterProfile(context,j,true))); })); }
}

class LodgesTab extends StatefulWidget { const LodgesTab({super.key}); @override State<LodgesTab> createState() => _LodgesTabState(); }
class _LodgesTabState extends State<LodgesTab> {
  List<Map<String,String>> lodges = [{"area":"Bodija - UI","price":"₦150k/year","type":"Self-con","desc":"Water, light","contact":"08087654321","postedBy":"Chioma D."}];
  void addLodgeDialog(){
    final a=TextEditingController(); final pr=TextEditingController(); final co=TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(
      title: const Text("Post a Lodge"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: a, decoration: const InputDecoration(labelText: "Area *")),
        TextField(controller: pr, decoration: const InputDecoration(labelText: "Price *")),
        TextField(controller: co, decoration: const InputDecoration(labelText: "WhatsApp *")),
      ]),
      actions: [ TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: (){ if(a.text.isEmpty||co.text.isEmpty) return; setState(()=>lodges.insert(0, {"area":a.text,"price":pr.text,"type":"","desc":"","contact":co.text,"postedBy":"You"})); Navigator.pop(ctx); }, child: const Text("Post")) ],
    ));
  }
  @override Widget build(BuildContext context){ return Scaffold(floatingActionButton: FloatingActionButton(onPressed: addLodgeDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)), body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: lodges.length, itemBuilder: (ctx,i){ final lg=lodges[i]; return Card(child: ListTile(title: Text(lg['area']!), subtitle: Text("${lg['price']}"), onTap: ()=>showPosterProfile(context,lg,false))); })); }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override Widget build(BuildContext context) {
    return const Center(child: Text("Naija Copas Connect - Oyo"));
  }
}
