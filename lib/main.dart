import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    return MaterialApp(title: 'Naija Copas Connect', debugShowCheckedModeBanner: false, theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF9F5F3)), home: const HomeScreen());
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

Future<void> openWhatsApp(String msg) async { try{ await launchUrl(Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msg)}"), mode: LaunchMode.externalApplication); }catch(_){} }
Future<void> openCall() async { try{ await launchUrl(Uri.parse("tel:+2348000000000")); }catch(_){} }
Future<void> openVideoCall(String room) async { try{ await launchUrl(Uri.parse("https://meet.jit.si/${room.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_NaijaCopas"), mode: LaunchMode.externalApplication); }catch(_){} }

// CONNECT - NORMAL SEARCH + CHAT
class ConnectTab extends StatefulWidget { const ConnectTab({super.key}); @override State<ConnectTab> createState() => _ConnectTabState(); }
class _ConnectTabState extends State<ConnectTab> {
  String search = "";
  final corpers = [{'name': 'Emeka D.', 'state': 'Oyo - Ibadan', 'ppa': 'UI Secondary School', 'skill': 'Tutoring'}, {'name': 'Chioma D.', 'state': 'Lagos - Ikeja', 'ppa': 'Tech Startup', 'skill': 'Graphics Design'}, {'name': 'Aisha B.', 'state': 'Abuja', 'ppa': 'Ministry', 'skill': 'Makeup'}, {'name': 'Tunde O.', 'state': 'Oyo - Ogbomoso', 'ppa': 'LAUTECH', 'skill': 'Web Dev'}, {'name': 'Fatima K.', 'state': 'Kano', 'ppa': 'School', 'skill': 'Baking'}];
  @override Widget build(BuildContext context){
    final filtered = corpers.where((c)=> c['name']!.toLowerCase().contains(search.toLowerCase()) || c['skill']!.toLowerCase().contains(search.toLowerCase())).toList();
    return Column(children: [Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v)=>setState(()=>search=v), decoration: InputDecoration(hintText: "Search corpers, skills...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))), Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (ctx,i){ final c=filtered[i]; return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text(c['name']![0])), title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${c['state']} • ${c['ppa']}\nSkill: ${c['skill']}"), isThreeLine: true, trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>ChatDetailScreen(corperName: c['name']!, corperSkill: c['skill']!))), child: const Text("Chat")))); }))]);
  }
}

class ChatDetailScreen extends StatefulWidget { final String corperName, corperSkill; const ChatDetailScreen({super.key, required this.corperName, required this.corperSkill}); @override State<ChatDetailScreen> createState() => _ChatDetailScreenState(); }
class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final List<Map<String,String>> messages = [{"text":"Hello! I saw your skill - ${''}", "isMe":"false", "time":"07:30"}];
  void send(){ if(_ctrl.text.trim().isEmpty) return; setState(()=>messages.insert(0, {"text":_ctrl.text.trim(), "isMe":"true", "time":"${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2,'0')}"})); _ctrl.clear(); }
  @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: Row(children: [CircleAvatar(child: Text(widget.corperName[0])), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.corperName, style: const TextStyle(fontSize: 16)), Text(widget.corperSkill, style: const TextStyle(fontSize: 11))])]), backgroundColor: Colors.green[700], foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.videocam), onPressed: ()=>openVideoCall(widget.corperName))]), body: Column(children: [Expanded(child: ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: messages.length, itemBuilder: (c,i){ final m=messages[i]; final isMe=m["isMe"]=="true"; return Align(alignment: isMe? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe? Colors.green[700]: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text(m["text"]!, style: TextStyle(color: isMe? Colors.white: Colors.black)))); })), Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Row(children: [Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: "Type message...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)))), const SizedBox(width: 8), CircleAvatar(backgroundColor: Colors.green[700], child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: send))]))])); }
}

// JOBS - NORMAL APP WITH ADD/DELETE
class JobsTab extends StatefulWidget { const JobsTab({super.key}); @override State<JobsTab> createState() => _JobsTabState(); }
class _JobsTabState extends State<JobsTab> {
  List<Map<String,String>> jobs = [{"title":"Home Lesson Teacher", "pay":"₦20k/month", "location":"Ibadan - Bodija", "desc":"Teach JSS2 Maths 3x weekly"}];
  void addJobDialog(){ final t=TextEditingController(); final p=TextEditingController(); final l=TextEditingController(); final d=TextEditingController(); showDialog(context: context, builder: (c)=>AlertDialog(title: const Text("Post a Job"), content: SingleChildScrollView(child: Column(children: [TextField(controller: t, decoration: const InputDecoration(labelText: "Job Title")), TextField(controller: p, decoration: const InputDecoration(labelText: "Pay e.g ₦20k/month")), TextField(controller: l, decoration: const InputDecoration(labelText: "Location")), TextField(controller: d, decoration: const InputDecoration(labelText: "Description"))])), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancel")), ElevatedButton(onPressed: (){ if(t.text.isNotEmpty){ setState(()=>jobs.insert(0, {"title":t.text, "pay":p.text.isEmpty?"₦Negotiable":p.text, "location":l.text, "desc":d.text})); Navigator.pop(c); }}, child: const Text("Post"))])); }
  @override Widget build(BuildContext context){ return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton.extended(onPressed: addJobDialog, backgroundColor: Colors.green[700], foregroundColor: Colors.white, label: const Text("Post Job"), icon: const Icon(Icons.add)), body: ListView.builder(padding: const EdgeInsets.all(15), itemCount: jobs.length, itemBuilder: (ctx,i){ final j=jobs[i]; return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(title: Text(j["title"]!, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${j["pay"]} • ${j["location"]}"), const SizedBox(height: 4), Text(j["desc"]??"", style: TextStyle(color: Colors.grey[600], fontSize: 13))]), trailing: IconButton(icon: const Icon(Icons.chat), onPressed: ()=>openWhatsApp("I'm interested in ${j["title"]} at ${j["location"]}")),)); })); }
}

class LodgesTab extends StatefulWidget { const LodgesTab({super.key}); @override State<LodgesTab> createState() => _LodgesTabState(); }
class _LodgesTabState extends State<LodgesTab> {
  List<Map<String,String>> lodges = [{"area":"Agbowo, UI", "price":"₦120k/year", "desc":"Self-con, water, light, 2 corpers needed"}];
  void addLodgeDialog(){ final a=TextEditingController(); final pr=TextEditingController(); final d=TextEditingController(); showDialog(context: context, builder: (c)=>AlertDialog(title: const Text("Post Lodge"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: a, decoration: const InputDecoration(labelText: "Area e.g Agbowo, UI")), TextField(controller: pr, decoration: const InputDecoration(labelText: "Price e.g ₦120k/year")), TextField(controller: d, decoration: const InputDecoration(labelText: "Description"))]), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancel")), ElevatedButton(onPressed: (){ if(a.text.isNotEmpty){ setState(()=>lodges.insert(0, {"area":a.text, "price":pr.text, "desc":d.text})); Navigator.pop(c); }}, child: const Text("Post"))])); }
  @override Widget build(BuildContext context){ return Scaffold(backgroundColor: const Color(0xFFF9F5F3), floatingActionButton: FloatingActionButton.extended(onPressed: addLodgeDialog, backgroundColor: Colors.green[700], foregroundColor: Colors.white, label: const Text("Post Lodge"), icon: const Icon(Icons.add)), body: ListView.builder(padding: const EdgeInsets.all(15), itemCount: lodges.length, itemBuilder: (ctx,i){ final l=lodges[i]; return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(title: Text("${l["area"]} - ${l["price"]}", style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(l["desc"]??""), trailing: IconButton(icon: const Icon(Icons.chat), onPressed: ()=>openWhatsApp("Interested in lodge at ${l["area"]}")))); })); }
}

// PROFILE - NORMAL APP, SAVES LOCALLY + FIREBASE
class ProfileTab extends StatefulWidget { const ProfileTab({super.key}); @override State<ProfileTab> createState() => _ProfileTabState(); }
class _ProfileTabState extends State<ProfileTab> {
  String name="Yunus Eunice", stateName="Oyo State", batch="Batch C 2025", ppa="Community Secondary School, Ibadan", skills="Tutoring, Makeup, Baking";
  String? photoUrl; File? localImage; final picker=ImagePicker();
  @override void initState(){ super.initState(); loadLocal(); }
  Future<void> loadLocal() async {
    final sp = await SharedPreferences.getInstance();
    setState((){
      name=sp.getString('name')??name; stateName=sp.getString('state')??stateName; batch=sp.getString('batch')??batch; ppa=sp.getString('ppa')??ppa; skills=sp.getString('skills')??skills; photoUrl=sp.getString('photoUrl');
      final path=sp.getString('localPhotoPath'); if(path!=null && File(path).existsSync()) localImage=File(path);
    });
  }
  Future<void> saveLocal() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('name', name); await sp.setString('state', stateName); await sp.setString('batch', batch); await sp.setString('ppa', ppa); await sp.setString('skills', skills);
    if(photoUrl!=null) await sp.setString('photoUrl', photoUrl!);
    if(localImage!=null) await sp.setString('localPhotoPath', localImage!.path);
  }
  Future<void> pickImage() async {
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if(x==null) return;
    setState(()=>localImage=File(x.path)); await saveLocal();
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture saved! ✅")));
    // Try Firebase in background
    try{ final user=FirebaseAuth.instance.currentUser; if(user!=null){ final ref=FirebaseStorage.instance.ref().child('profile_pics/${user.uid}.jpg'); await ref.putFile(File(x.path)); final url=await ref.getDownloadURL(); setState(()=>photoUrl=url); await saveLocal(); } }catch(_){}
  }
  void editDialog(){
    final nc=TextEditingController(text: name); final sc=TextEditingController(text: stateName); final bc=TextEditingController(text: batch); final pc=TextEditingController(text: ppa); final skc=TextEditingController(text: skills);
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text("Edit Profile"), content: SingleChildScrollView(child: Column(children: [TextField(controller: nc, decoration: const InputDecoration(labelText: "Full Name")), TextField(controller: sc, decoration: const InputDecoration(labelText: "State")), TextField(controller: bc, decoration: const InputDecoration(labelText: "Batch")), TextField(controller: pc, decoration: const InputDecoration(labelText: "PPA")), TextField(controller: skc, decoration: const InputDecoration(labelText: "Skills"))])), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancel")), ElevatedButton(onPressed: (){ setState((){ name=nc.text.trim().isEmpty?name:nc.text.trim(); stateName=sc.text.trim().isEmpty?stateName:sc.text.trim(); batch=bc.text.trim().isEmpty?batch:bc.text.trim(); ppa=pc.text.trim().isEmpty?ppa:pc.text.trim(); skills=skc.text.trim().isEmpty?skills:skc.text.trim(); }); Navigator.pop(c); saveLocal(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile saved! ✅"))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), child: const Text("Save"))]));
  }
  @override Widget build(BuildContext context){
    ImageProvider? img; if(localImage!=null) img=FileImage(localImage!); else if(photoUrl!=null) img=NetworkImage(photoUrl!);
    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 10),
      Center(child: Stack(children: [CircleAvatar(radius: 60, backgroundColor: Colors.green[100], backgroundImage: img, child: img==null? Text(name[0], style: TextStyle(fontSize: 40, color: Colors.green[700], fontWeight: FontWeight.bold)): null), Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.green[700], child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: pickImage)))])),
      const SizedBox(height: 16), Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), Center(child: Text("$stateName • $batch", style: TextStyle(color: Colors.grey[600]))),
      const SizedBox(height: 20),
      Card(child: ListTile(leading: Icon(Icons.school, color: Colors.green[700]), title: const Text("PPA"), subtitle: Text(ppa))),
      Card(child: ListTile(leading: Icon(Icons.star, color: Colors.green[700]), title: const Text("Skills"), subtitle: Text(skills))),
      Card(child: ListTile(leading: Icon(Icons.verified_user, color: Colors.green[700]), title: const Text("Status"), subtitle: const Text("Verified Corper - Trusted Member"))),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: editDialog, icon: const Icon(Icons.edit), label: const Text("Edit Profile"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: (){ showDialog(context: context, builder: (c)=>AlertDialog(title: const Text("About"), content: const Text("Naija Copas Connect v2.0 - Normal App\n\n• Works offline\n• Saves locally\n• Edit profile works\n• Post jobs/lodges\n• Chat works\n\nBuilt for Corpers."), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Close"))])); }, icon: const Icon(Icons.info_outline), label: const Text("About App")),
    ]);
  }
}
