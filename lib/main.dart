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
  final screens = [const CorperConnectTab(), const JobsTab(), const LodgesTab(), ProfileTab()];
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
  final encoded = Uri.encodeComponent(message);
  final url = Uri.parse("https://wa.me/?text=$encoded");
  await launchUrl(url, mode: LaunchMode.externalApplication);
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
    showDialog(context: context, builder: (ctx)=>AlertDialog(title: Text('Post New Job'), content: SingleChildScrollView(child: Column(children: [TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Job Title')), TextField(controller: payCtrl, decoration: InputDecoration(labelText: 'Pay')), TextField(controller: locationCtrl, decoration: InputDecoration(labelText: 'Location')), TextField(controller: typeCtrl, decoration: InputDecoration(labelText: 'Type'))])), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text('Cancel')), ElevatedButton(onPressed: (){ if(titleCtrl.text.isNotEmpty){ setState(()=>jobs.insert(0, {'title':titleCtrl.text,'pay':payCtrl.text.isEmpty?'Negotiable':payCtrl.text,'location':locationCtrl.text.isEmpty?'Oyo':locationCtrl.text,'type':typeCtrl.text.isEmpty?'New':typeCtrl.text})); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job posted! ✅'))); } }, child: Text('Post Job'))]));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color(0xFFF5F9F5), floatingActionButton: FloatingActionButton.extended(onPressed: showAddJobDialog, backgroundColor: Colors.green[700], icon: Icon(Icons.add, color: Colors.white), label: Text('Post Job', style: TextStyle(color: Colors.white))), body: ListView.builder(padding: EdgeInsets.all(16), itemCount: jobs.length, itemBuilder: (context,index){ final job = jobs[index]; return Card(margin: EdgeInsets.only(bottom: 12), child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(job['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Chip(label: Text(job['type']!, style: TextStyle(fontSize: 10)), backgroundColor: Colors.green[50])]), SizedBox(height: 8), Text('${job['pay']} • ${job['location']}'), SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]), onPressed: ()=>openWhatsApp("Hello, I saw *${job['title']}* (${job['pay']} - ${job['location']}) on Naija Copas Connect. I'm a corper in Oyo and I'm interested!"), child: Text('Apply via WhatsApp', style: TextStyle(color: Colors.white))))]))); }));
  }
}

class LodgesTab extends StatefulWidget {
  const LodgesTab({super.key});
  @override
  State<LodgesTab> createState() => _LodgesTabState();
}
class _LodgesTabState extends State<LodgesTab> {
  List<Map<String,String>> lodges = [
    {'area':'Agbowo, UI','price':'₦180k/year','desc':'Self-con, water, light, 2 corpers needed'},
    {'area':'Sango, Ibadan','price':'₦120k/year','desc':'Single room, shared kitchen, close to bus stop'},
    {'area':'Akobo, Ibadan','price':'₦200k/year','desc':'Mini flat for 2 corpers, fenced & gated'},
  ];
  void showAddLodgeDialog() {
    final areaCtrl = TextEditingController(); final priceCtrl = TextEditingController(); final descCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx)=>AlertDialog(title: Text('Post Lodge / Room'), content: SingleChildScrollView(child: Column(children: [TextField(controller: areaCtrl, decoration: InputDecoration(labelText: 'Area')), TextField(controller: priceCtrl, decoration: InputDecoration(labelText: 'Price')), TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Description'))])), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text('Cancel')), ElevatedButton(onPressed: (){ if(areaCtrl.text.isNotEmpty){ setState(()=>lodges.insert(0, {'area':areaCtrl.text,'price':priceCtrl.text.isEmpty?'Negotiable':priceCtrl.text,'desc':descCtrl.text.isEmpty?'Corper lodge':descCtrl.text})); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lodge posted! ✅'))); } }, child: Text('Post Lodge'))]));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color(0xFFF5F9F5), floatingActionButton: FloatingActionButton.extended(onPressed: showAddLodgeDialog, backgroundColor: Colors.green[700], icon: Icon(Icons.add, color: Colors.white), label: Text('Post Lodge', style: TextStyle(color: Colors.white))), body: ListView.builder(padding: EdgeInsets.all(16), itemCount: lodges.length, itemBuilder: (context,index){ final lodge = lodges[index]; return Card(margin: EdgeInsets.only(bottom: 12), child: ListTile(leading: Icon(Icons.home_work, color: Colors.green[700], size: 40), title: Text(lodge['area']!, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${lodge['price']}\n${lodge['desc']}'), isThreeLine: true, trailing: IconButton(icon: Icon(Icons.call, color: Colors.green), onPressed: openCall))); }));
  }
}

// VERSION 4 - EDITABLE PROFILE
class ProfileTab extends StatefulWidget {
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}
class _ProfileTabState extends State<ProfileTab> {
  String name = "Eunice";
  String state = "Oyo State";
  String batch = "Batch C 2025";
  String ppa = "Community Secondary School, Ibadan";
  String skill = "Tutoring • Makeup • Content Creation";
  String phone = "080...";

  void editProfile() {
    final nameCtrl = TextEditingController(text: name);
    final stateCtrl = TextEditingController(text: state);
    final batchCtrl = TextEditingController(text: batch);
    final ppaCtrl = TextEditingController(text: ppa);
    final skillCtrl = TextEditingController(text: skill);
    final phoneCtrl = TextEditingController(text: phone);

    showDialog(context: context, builder: (ctx)=>AlertDialog(
      title: Text('Edit Profile'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Full Name')),
        TextField(controller: stateCtrl, decoration: InputDecoration(labelText: 'State & LGA e.g. Oyo - Ibadan North')),
        TextField(controller: batchCtrl, decoration: InputDecoration(labelText: 'Batch e.g. Batch C 2025')),
        TextField(controller: ppaCtrl, decoration: InputDecoration(labelText: 'PPA Name')),
        TextField(controller: skillCtrl, decoration: InputDecoration(labelText: 'Your Skills e.g. Tutoring, Graphics')),
        TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: 'WhatsApp Number')),
      ])),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text('Cancel')),
        ElevatedButton(onPressed: (){
          setState((){
            name = nameCtrl.text; state = stateCtrl.text; batch = batchCtrl.text; ppa = ppaCtrl.text; skill = skillCtrl.text; phone = phoneCtrl.text;
          });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated! ✅')));
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]), child: Text('Save', style: TextStyle(color: Colors.white)))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: EdgeInsets.all(24), children: [
      Center(child: Column(children: [
        Stack(children: [
          CircleAvatar(radius: 55, backgroundColor: Colors.green[100], child: Icon(Icons.person, size: 60, color: Colors.green[700])),
          Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.green[700], radius: 18, child: IconButton(icon: Icon(Icons.edit, size: 18, color: Colors.white), onPressed: editProfile))),
        ]),
        SizedBox(height: 16),
        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('$state | $batch', style: TextStyle(color: Colors.grey[700])),
        SizedBox(height: 8),
        Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)), child: Text('Connecting Nigerians to real opportunities', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.green[700]))),
      ])),
      SizedBox(height: 30),
      Text('My Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      SizedBox(height: 10),
      Card(child: ListTile(leading: Icon(Icons.work, color: Colors.green[700]), title: Text('PPA'), subtitle: Text(ppa))),
      Card(child: ListTile(leading: Icon(Icons.star, color: Colors.green[700]), title: Text('Skills'), subtitle: Text(skill))),
      Card(child: ListTile(leading: Icon(Icons.phone, color: Colors.green[700]), title: Text('WhatsApp'), subtitle: Text(phone))),
      SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: editProfile, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: EdgeInsets.all(16)), icon: Icon(Icons.edit, color: Colors.white), label: Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 16)))),
      SizedBox(height: 10),
      Center(child: Text('Version 4 - Editable Profile ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
    ]);
  }
}
