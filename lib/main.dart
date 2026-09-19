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
  final List<Widget> screens = [ConnectTab(), JobsTab(), LodgesTab(), ProfileTab()];
  final List<String> titles = ["Naija Copas Connect", "Naija Jobs", "Corper Lodge", "Profile"];
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
  final waMe = Uri.parse("https://wa.me/$clean?text=${Uri.encodeComponent(msg)}");
  final waApp = Uri.parse("whatsapp://send?phone=$clean&text=${Uri.encodeComponent(msg)}");
  try { if (await canLaunchUrl(waMe)) { await launchUrl(waMe, mode: LaunchMode.externalApplication); return; } } catch (_) {}
  try { if (await canLaunchUrl(waApp)) { await launchUrl(waApp, mode: LaunchMode.externalApplication); return; } } catch (_) {}
  try { await launchUrl(waMe, mode: LaunchMode.platformDefault); } catch (_) {}
}

class ConnectTab extends StatefulWidget { ConnectTab({super.key}); @override State<ConnectTab> createState() => _ConnectTabState(); }
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
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Create Post"),
      content: TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: "What's happening in your PPA?")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async { if (textCtrl.text.trim().isEmpty) return; try { await FirebaseFirestore.instance.collection('posts').add({'text': textCtrl.text.trim(), 'state': myState, 'uid': FirebaseAuth.instance.currentUser?.uid?? 'anon', 'userName': myName, 'createdAt': FieldValue.serverTimestamp()}); } catch (_) {} if (mounted) Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post")),
      ],
    ));
  }
  @override Widget build(BuildContext context) {
    final filtered = corpers.where((c) => c['name']!.toLowerCase().contains(search.toLowerCase()) || c['skill']!.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton.extended(onPressed: createPostDialog, backgroundColor: Colors.green[700], icon: const Icon(Icons.add, color: Colors.white), label: const Text("Post Feed", style: TextStyle(color: Colors.white))),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Corper Feed", style: TextStyle(fontWeight: FontWeight.bold)), InkWell(onTap: createPostDialog, child: Text("Post gist", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12)))]),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).limit(10).snapshots(), builder: (context, snap) {
            if (snap.hasError) return const Text("Enable Anonymous in Firebase Auth", style: TextStyle(fontSize: 11, color: Colors.red));
            if (!snap.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            if (snap.data!.docs.isEmpty) return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)), child: const Text("No gist yet. Be the first! 🎉", style: TextStyle(fontSize: 12)));
            var docs = snap.data!.docs;
            return SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: docs.length, itemBuilder: (ctx, i) { var d = docs[i].data() as Map<String, dynamic>; return Container(width: 220, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF9F5F3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['userName']?? 'Corper', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), const SizedBox(height: 4), Expanded(child: Text(d['text']?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))), Text(d['state']?? 'Oyo', style: TextStyle(fontSize: 10, color: Colors.grey[600]))])); }));
          }),
        ])),
        Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v) => setState(() => search = v), decoration: InputDecoration(hintText: "Search name, skill...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: filtered.length, itemBuilder: (ctx, i) { final c = filtered[i]; return Card(child: ListTile(title: Text(c['name']!), subtitle: Text("${c['state']} - ${c['skill']}"), trailing: ElevatedButton(onPressed: () => openWhatsAppDirect(c['phone']!, "Hello ${c['name']}, I saw you on Naija Copas Connect"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Chat")))); })),
      ]),
    );
  }
}

class JobsTab extends StatefulWidget { const JobsTab({super.key}); @override State<JobsTab> createState() => _JobsTabState(); }
class _JobsTabState extends State<JobsTab> {
  List<Map<String, String>> jobs = [{"title": "Home Lesson Teacher", "pay": "₦20k/month", "location": "Ibadan - Bodija", "desc": "Teach JSS2 Maths", "contact": "08012345678", "postedBy": "Emeka D."}];
  Future<void> loadJobs() async { final sp = await SharedPreferences.getInstance(); final s = sp.getString('jobs_list'); if (s!= null) { try { final List l = jsonDecode(s); setState(() => jobs = l.map((e) => Map<String, String>.from(e)).toList()); } catch (_) {} } }
  Future<void> saveJobs() async { final sp = await SharedPreferences.getInstance(); await sp.setString('jobs_list', jsonEncode(jobs)); }
  @override void initState() { super.initState(); loadJobs(); }
  void addJobDialog() { final t = TextEditingController(); final p = TextEditingController(); final l = TextEditingController(); final c = TextEditingController(); showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Post a Job"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: "Job Title *")), TextField(controller: p, decoration: const InputDecoration(labelText: "Pay")), TextField(controller: l, decoration: const InputDecoration(labelText: "Location")), TextField(controller: c, decoration: const InputDecoration(labelText: "WhatsApp *"))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () { if (t.text.isEmpty || c.text.isEmpty) return; setState(() => jobs.insert(0, {"title": t.text, "pay": p.text, "location": l.text, "desc": "", "contact": c.text, "postedBy": "You"})); saveJobs(); Navigator.pop(ctx); }, child: const Text("Post"))])); }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton(onPressed: addJobDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)), body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: jobs.length, itemBuilder: (ctx, i) { final j = jobs[i]; return Card(child: ListTile(title: Text(j['title']!), subtitle: Text("${j['pay']} - ${j['location']}"), trailing: IconButton(icon: const Icon(Icons.send, color: Colors.green), onPressed: ()=>openWhatsAppDirect(j['contact']!, "Hello, I saw your job ${j['title']} on Naija Copas Connect")))); })); }
}

// ===== NEW LODGE TAB WITH LOCATION BOX + DELETE - NO MAP =====
class LodgesTab extends StatefulWidget { const LodgesTab({super.key}); @override State<LodgesTab> createState() => _LodgesTabState(); }
class _LodgesTabState extends State<LodgesTab> {
  List<Map<String, String>> lodges = [
    {"category": "I HAVE Lodge Info", "area": "Bodija - UI", "location": "Opposite UI second gate, 2 mins to main gate", "price": "₦150k/year", "type": "Self-con", "desc": "Water, light, fenced", "contact": "08087654321", "postedBy": "Chioma D.", "date": "Sep 19"}
  ];
  String filter = "All";

  Future<void> loadLodges() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString('lodges_list_v3');
    if (s!= null) { try { final List l = jsonDecode(s); setState(()=> lodges = l.map((e)=> Map<String,String>.from(e)).toList()); } catch(_){} }
  }
  Future<void> saveLodges() async { final sp = await SharedPreferences.getInstance(); await sp.setString('lodges_list_v3', jsonEncode(lodges)); }
  @override void initState() { super.initState(); loadLodges(); }

  void addLodgeDialog() {
    final areaCtrl = TextEditingController(); final locationCtrl = TextEditingController(); final priceCtrl = TextEditingController(); final typeCtrl = TextEditingController(); final descCtrl = TextEditingController(); final contactCtrl = TextEditingController();
    String category = "I NEED Lodge - Looking for apartment";
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text("Post Lodge"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: "Post Type *"), items: const [DropdownMenuItem(value: "I NEED Lodge - Looking for apartment", child: Text("I NEED - Apartment")), DropdownMenuItem(value: "I NEED Roommate to join me", child: Text("I NEED - Roommate")), DropdownMenuItem(value: "I HAVE Lodge Info", child: Text("I HAVE - Lodge Info"))], onChanged: (v)=> setD(()=> category = v!)),
        const SizedBox(height: 10),
        TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: "Area *", hintText: "Bodija, Akobo, Sango")),
        const SizedBox(height: 8),
        TextField(controller: locationCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Location Details *", hintText: "Type full location: e.g Behind FoodCo Bodija, close to UI", border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price / Budget *")),
        TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: "House Type", hintText: "Self-con, Single room")),
        TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "More Info")),
        TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: "WhatsApp Number *"), keyboardType: TextInputType.phone),
      ])),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: (){
          if(areaCtrl.text.isEmpty || locationCtrl.text.isEmpty || contactCtrl.text.isEmpty){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Area, Location Details & WhatsApp required")));
            return;
          }
          setState(()=> lodges.insert(0, {"category": category, "area": areaCtrl.text, "location": locationCtrl.text, "price": priceCtrl.text, "type": typeCtrl.text, "desc": descCtrl.text, "contact": contactCtrl.text, "postedBy": "You", "date": "Now"}));
          saveLodges(); Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Post"))
      ],
    )));
  }

  void deleteLodge(int idx){ showDialog(context: context, builder: (ctx)=> AlertDialog(title: const Text("Delete Post?"), content: const Text("No longer valid? Delete it?"), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: (){ setState(()=> lodges.removeAt(idx)); saveLodges(); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete", style: TextStyle(color: Colors.white))) ])); }

  @override Widget build(BuildContext context){
    List<Map<String,String>> filtered = filter=="All"? lodges : lodges.where((l)=> l['category']!.contains(filter)).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      floatingActionButton: FloatingActionButton(onPressed: addLodgeDialog, backgroundColor: Colors.green[700], child: const Icon(Icons.add, color: Colors.white)),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_chip("All"), _chip("I NEED"), _chip("I HAVE")]))),
        Expanded(child: filtered.isEmpty? const Center(child: Text("No lodge here. Tap + to post")) :
          ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (ctx,i){
            final lg = filtered[i]; final realIdx = lodges.indexOf(lg); bool isNeed = lg['category']!.contains("NEED"); bool isMine = lg['postedBy']=="You";
            return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 4), decoration: BoxDecoration(color: isNeed? Colors.orange[100]:Colors.green[100], borderRadius: BorderRadius.circular(20)), child: Text(isNeed? "LOOKING FOR" : "AVAILABLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNeed? Colors.orange[800]:Colors.green[800]))), Text(lg['date']!, style: TextStyle(fontSize: 10, color: Colors.grey[500]))]),
              const SizedBox(height: 8),
              Text(lg['area']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.location_on, size: 16, color: Colors.red), const SizedBox(width: 6), Expanded(child: Text(lg['location']!, style: const TextStyle(fontSize: 13)))])),
              const SizedBox(height: 8),
              Text("${lg['price']!} • ${lg['type']!}", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              if(lg['desc']!.isNotEmpty)...[const SizedBox(height: 4), Text(lg['desc']!, style: const TextStyle(fontSize: 13))],
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("By ${lg['postedBy']}", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Row(children: [if(isMine) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: ()=> deleteLodge(realIdx)), ElevatedButton(onPressed: ()=> openWhatsAppDirect(lg['contact']!, "Hello, I saw your lodge: ${lg['area']} - ${lg['location']} on Naija Copas Connect"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Chat"))]),
              ]),
            ])));}
          )
        ),
      ]),
    );
  }
  Widget _chip(String label){ bool sel = filter==label; return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label, style: TextStyle(fontSize: 12, color: sel? Colors.white:Colors.black)), selected: sel, selectedColor: Colors.green[700], onSelected: (v)=> setState(()=> filter=label))); }
}

class ProfileTab extends StatefulWidget { const ProfileTab({super.key}); @override State<ProfileTab> createState() => _ProfileTabState(); }
class _ProfileTabState extends State<ProfileTab> {
  String name = "Yunus Eunice"; String stateBatch = "Oyo State - Batch C 2025"; String ppa = "Community Secondary School, Ibadan"; String skills = "Tutoring, Makeup, Baking"; String? profileImageBase64;
  @override void initState() { super.initState(); loadProfile(); }
  Future<void> loadProfile() async { final sp = await SharedPreferences.getInstance(); setState(() { name = sp.getString('name')?? name; stateBatch = sp.getString('stateBatch')?? stateBatch; ppa = sp.getString('ppa')?? ppa; skills = sp.getString('skills')?? skills; profileImageBase64 = sp.getString('profile_image'); }); }
  Future<void> saveProfile(String n, String sb, String p, String sk) async { final sp = await SharedPreferences.getInstance(); await sp.setString('name', n); await sp.setString('stateBatch', sb); await sp.setString('ppa', p); await sp.setString('skills', sk); setState(() { name = n; stateBatch = sb; ppa = p; skills = sk; }); }
  Future<void> pickImage() async { final picker = ImagePicker(); final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60); if (picked == null) return; final bytes = await File(picked.path).readAsBytes(); final base64Str = base64Encode(bytes); final sp = await SharedPreferences.getInstance(); await sp.setString('profile_image', base64Str); setState(() => profileImageBase64 = base64Str); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'))); }
  void editDialog() { final nCtrl = TextEditingController(text: name); final sbCtrl = TextEditingController(text: stateBatch); final pCtrl = TextEditingController(text: ppa); final skCtrl = TextEditingController(text: skills); showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Edit Profile"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nCtrl, decoration: const InputDecoration(labelText: "Name")), TextField(controller: sbCtrl, decoration: const InputDecoration(labelText: "State - Batch")), TextField(controller: pCtrl, decoration: const InputDecoration(labelText: "PPA")), TextField(controller: skCtrl, decoration: const InputDecoration(labelText: "Skills"))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () { saveProfile(nCtrl.text, sbCtrl.text, pCtrl.text, skCtrl.text); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Save"))])); }
  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF9F5F3), body: ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 20),
      Center(child: Stack(children: [CircleAvatar(radius: 50, backgroundColor: Colors.green[100], backgroundImage: profileImageBase64!= null? MemoryImage(base64Decode(profileImageBase64!)) : null, child: profileImageBase64 == null? Text(name.isNotEmpty? name[0].toUpperCase() : "Y", style: TextStyle(fontSize: 40, color: Colors.green[700], fontWeight: FontWeight.bold)) : null), Positioned(bottom: 0, right: 0, child: InkWell(onTap: pickImage, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.green[700], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, size: 18, color: Colors.white))))])),
      const SizedBox(height: 6), Center(child: TextButton(onPressed: pickImage, child: const Text("Change Photo"))),
      const SizedBox(height: 6), Center(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))), Center(child: Text(stateBatch, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.school, color: Colors.green[700]), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("PPA", style: TextStyle(fontWeight: FontWeight.bold)), Text(ppa)])) ])),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.star, color: Colors.green[700]), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Skills", style: TextStyle(fontWeight: FontWeight.bold)), Text(skills)])) ])),
      const SizedBox(height: 20),
      SizedBox(height: 48, child: ElevatedButton.icon(onPressed: editDialog, icon: const Icon(Icons.edit, size: 16), label: const Text("Edit Profile"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]));
  }
}
