import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const NaijaCopasApp());
}

class NaijaCopasApp extends StatelessWidget {
  const NaijaCopasApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naija Copas Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true, scaffoldBackgroundColor: Color(0xFFF5F9F5)),
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
  final screens = [const CorperConnectTab(), const JobsTab(), const LodgesTab(), const ProfileTab()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(currentIndex==0?'Naija Copas Connect':currentIndex==1?'Real Jobs':currentIndex==2?'Corper Lodges':'My Profile'), backgroundColor: Colors.green[700], foregroundColor: Colors.white, centerTitle: true),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex, onTap: (i)=>setState(()=>currentIndex=i), selectedItemColor: Colors.green[700], unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed,
        items: const [BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Connect'), BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'), BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Lodges'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile')],
      ),
    );
  }
}

Future<void> openWhatsApp(String message) async {
  // Replace with your WhatsApp number later, for now opens WhatsApp
  final encoded = Uri.encodeComponent(message);
  final url = Uri.parse("https://wa.me/?text=$encoded");
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    // fallback
  }
}
Future<void> openCall() async {
  final url = Uri.parse("tel:+2348000000000");
  await launchUrl(url);
}

class CorperConnectTab extends StatelessWidget {
  const CorperConnectTab({super.key});
  @override
  Widget build(BuildContext context) {
    final corpers = [{'name':'Tolu A.','state':'Oyo - Ibadan','ppa':'UI Secondary School','skill':'Tutoring'},{'name':'Chidi O.','state':'Lagos - Ikeja','ppa':'Tech Startup','skill':'Graphics Design'},{'name':'Aisha B.','state':'Abuja','ppa':'Ministry','skill':'Makeup'}];
    return ListView(padding: EdgeInsets.all(16), children: [
      Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green[700], borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Connecting Nigerians to real opportunities', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Find corpers near you, share PPA gist, find roommate', style: TextStyle(color: Colors.white70))])),
      SizedBox(height: 20), Text('Corpers Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 10),
     ...corpers.map((c)=>Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text(c['name']![0])), title: Text(c['name']!), subtitle: Text('${c['state']} • ${c['ppa']}\nSkill: ${c['skill']}'), trailing: ElevatedButton(onPressed: ()=>openWhatsApp("Hello ${c['name']}, I saw you on Naija Copas Connect, let's connect! I need ${c['skill']}"), child: Text('Connect'))))),
    ]);
  }
}

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});
  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  List<Map<String,String>> jobs = [
    {'title':'Home Lesson Teacher','pay':'₦40k/month','location':'Ibadan - Bodija','type':'Part-time'},
    {'title':'Social Media Manager','pay':'₦60k/month','location':'Remote','type':'Remote'},
    {'title':'PPA Assistant Needed','pay':'₦30k + Accommodation','location':'Oyo','type':'PPA'},
    {'title':'Weekend Ushering Job','pay':'₦10k/day','location':'Lagos','type':'Gig'},
  ];

  void showAddJobDialog() {
    final titleCtrl = TextEditingController(); final payCtrl = TextEditingController(); final locationCtrl = TextEditingController(); final typeCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(title: Text('Post New Job'), content: SingleChildScrollView(child: Column(children: [TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Job Title e.g. Makeup Artist')), TextField(controller: payCtrl, decoration: InputDecoration(labelText: 'Pay e.g. ₦20k/day')), TextField(controller: locationCtrl, decoration: InputDecoration(labelText: 'Location e.g. Ibadan')), TextField(controller: typeCtrl, decoration: InputDecoration(labelText: 'Type e.g. Part-time, Remote, Gig'))])), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text('Cancel')), ElevatedButton(onPressed: (){ if(titleCtrl.text.isNotEmpty){ setState(()=>jobs.insert(0, {'title':titleCtrl.text,'pay':payCtrl.text.isEmpty?'Negotiable':payCtrl.text,'location':locationCtrl.text.isEmpty?'Oyo':locationCtrl.text,'type':typeCtrl.text.isEmpty?'New':typeCtrl.text})); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job posted! ✅'))); } }, child: Text('Post Job'))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color(0xFFF5F9F5), floatingActionButton: FloatingActionButton.extended(onPressed: showAddJobDialog, backgroundColor: Colors.green[700], icon: Icon(Icons.add, color: Colors.white), label: Text('Post Job', style: TextStyle(color: Colors.white))), body: ListView.builder(padding: EdgeInsets.all(16), itemCount: jobs.length, itemBuilder: (context,index){ final job = jobs[index]; return Card(margin: EdgeInsets.only(bottom: 12), child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(job['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Chip(label: Text(job['type']!, style: TextStyle(fontSize: 10)), backgroundColor: Colors.green[50])]), SizedBox(height: 8), Text('${job['pay']} • ${job['location']}'), SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]), onPressed: ()=>openWhatsApp("Hello, I saw *${job['title']}* (${job['pay']} - ${job['location']}) on Naija Copas Connect. I'm a corper in Oyo and I'm interested! My name is Eunice."), child: Text('Apply via WhatsApp', style: TextStyle(color: Colors.white))))]))); }));
  }
}

class LodgesTab extends StatefulWidget {
  const LodgesTab({super.key});
  @override
  State<LodgesTab> createState() => _LodgesTabState();
}

class _LodgesTabState extends State<LodgesTab> {
  List<Map<String,String>> lodges = [
    {'area':'Igoba, Akure','price':'300k/year','desc':'self-con, water, pop'},
    {'area':'Agbowo, UI','price':'₦180k/year','desc':'Self-con, water, light, 2 corpers needed'},
    {'area':'Sango, Ibadan','price':'₦120k/year','desc':'Single room, shared kitchen, close to bus stop'},
    {'area':'Akobo, Ibadan','price':'₦200k/year','desc':'Mini flat for 2 corpers, fenced & gated'},
  ];

  void showAddLodgeDialog() {
    final areaCtrl = TextEditingController(); final priceCtrl = TextEditingController(); final descCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(title: Text('Post Lodge / Room'), content: SingleChildScrollView(child: Column(children: [TextField(controller: areaCtrl, decoration: InputDecoration(labelText: 'Area e.g. Agbowo, UI')), TextField(controller: priceCtrl, decoration: InputDecoration(labelText: 'Price e.g. ₦150k/year')), TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Description e.g. Self-con, water...'))])), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text('Cancel')), ElevatedButton(onPressed: (){ if(areaCtrl.text.isNotEmpty){ setState(()=>lodges.insert(0, {'area':areaCtrl.text,'price':priceCtrl.text.isEmpty?'Negotiable':priceCtrl.text,'desc':descCtrl.text.isEmpty?'Corper lodge':descCtrl.text})); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lodge posted! ✅'))); } }, child: Text('Post Lodge'))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color(0xFFF5F9F5), floatingActionButton: FloatingActionButton.extended(onPressed: showAddLodgeDialog, backgroundColor: Colors.green[700], icon: Icon(Icons.add, color: Colors.white), label: Text('Post Lodge', style: TextStyle(color: Colors.white))), body: ListView.builder(padding: EdgeInsets.all(16), itemCount: lodges.length, itemBuilder: (context,index){ final lodge = lodges[index]; return Card(margin: EdgeInsets.only(bottom: 12), child: ListTile(leading: Icon(Icons.home_work, color: Colors.green[700], size: 40), title: Text(lodge['area']!, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${lodge['price']}\n${lodge['desc']}'), isThreeLine: true, trailing: IconButton(icon: Icon(Icons.call, color: Colors.green), onPressed: openCall))); }));
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 50, backgroundColor: Colors.green[100], child: Icon(Icons.person, size: 50, color: Colors.green[700])), SizedBox(height: 16), Text('Eunice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text('Oyo State | Batch C 2025'), SizedBox(height: 24), Text('Version 3 - WhatsApp Ready ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Tagline: Connecting Nigerians to real opportunities', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic)), SizedBox(height: 20), Text('Now Apply & Connect opens WhatsApp!', style: TextStyle(fontWeight: FontWeight.bold)) ])));
  }
}
