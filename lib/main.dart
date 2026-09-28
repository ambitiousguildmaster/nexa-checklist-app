
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NexaApp());

class Task {
  String id, title, project, priority, due, reminder, repeat;
  bool done;
  Task({
    required this.id,
    required this.title,
    this.project = 'Personal',
    this.priority = 'NORMAL',
    this.due = 'Today',
    this.reminder = 'None',
    this.repeat = 'Does not repeat',
    this.done = false,
  });
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'project':project,'priority':priority,'due':due,'reminder':reminder,'repeat':repeat,'done':done};
  factory Task.fromJson(Map<String,dynamic> j)=>Task(id:j['id'],title:j['title'],project:j['project']??'Personal',priority:j['priority']??'NORMAL',due:j['due']??'Today',reminder:j['reminder']??'None',repeat:j['repeat']??'Does not repeat',done:j['done']??false);
}

class NexaStore extends ChangeNotifier {
  final List<Task> tasks = [
    Task(id:'1',title:'Finish product prototype',project:'Product',priority:'HIGH',due:'10:30 AM',reminder:'30 min before'),
    Task(id:'2',title:'Send project update',project:'Work',due:'1:00 PM'),
    Task(id:'3',title:'Review landing page',project:'Design',due:'4:30 PM',done:true),
    Task(id:'4',title:'Plan tomorrow',project:'Personal',due:'7:00 PM'),
    Task(id:'5',title:'Read 20 pages',project:'Personal',due:'8:30 PM',done:true),
  ];
  final projects = ['Product Design','Best Wishes Academy','Personal','Ideas'];
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString('tasks');
    if (raw != null) {
      tasks
        ..clear()
        ..addAll((jsonDecode(raw) as List).map((e)=>Task.fromJson(e)));
    }
    notifyListeners();
  }
  Future<void> save() async => _prefs?.setString('tasks',jsonEncode(tasks.map((e)=>e.toJson()).toList()));
  void toggle(Task t){t.done=!t.done; save(); notifyListeners();}
  void add(Task t){tasks.insert(0,t);save();notifyListeners();}
  void remove(Task t){tasks.remove(t);save();notifyListeners();}
  int get completed => tasks.where((e)=>e.done).length;
  double get progress => tasks.isEmpty?0:completed/tasks.length;
}

class NexaApp extends StatefulWidget {
  const NexaApp({super.key});
  @override State<NexaApp> createState()=>_NexaAppState();
}
class _NexaAppState extends State<NexaApp> {
  final store=NexaStore();
  @override void initState(){super.initState();store.init();}
  @override Widget build(BuildContext context)=>ChangeNotifierProvider(store:store,child:const _App());
}

class ChangeNotifierProvider extends InheritedNotifier<NexaStore> {
  const ChangeNotifierProvider({super.key,required NexaStore store,required Widget child}):super(notifier:store,child:child);
  static NexaStore of(BuildContext c)=>c.dependOnInheritedWidgetOfExactType<ChangeNotifierProvider>()!.notifier!;
}

class _App extends StatefulWidget { const _App(); @override State<_App> createState()=>_AppState(); }
class _AppState extends State<_App> {
  int index=0;
  final pages=const [DashboardPage(),TodayPage(),ProjectsPage(),InsightsPage(),SettingsPage()];
  @override Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title:'NEXA',
      theme:ThemeData.dark(useMaterial3:true).copyWith(scaffoldBackgroundColor:const Color(0xff070b18),colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff38d9ff),brightness:Brightness.dark),fontFamily:'Inter'),
      home:Scaffold(
        body:Stack(children:[Positioned.fill(child:CustomPaint(painter:GlowPainter())),SafeArea(child:pages[index])]),
        floatingActionButton:FloatingActionButton(onPressed:()=>showDialog(context:context,builder:(_)=>const AddTaskDialog()),backgroundColor:const Color(0xff38d9ff),child:const Icon(Icons.add,color:Colors.black)),floatingActionButtonLocation:FloatingActionButtonLocation.centerDocked,bottomNavigationBar:GlassNav(index:index,onTap:(i)=>setState(()=>index=i)),
      ),
    );
  }
}

class GlowPainter extends CustomPainter {
  @override void paint(Canvas c,Size s){
    final p1=Paint()..shader=RadialGradient(colors:[const Color(0xff36d9ff).withOpacity(.16),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(s.width*.2,s.height*.12),radius:220));
    final p2=Paint()..shader=RadialGradient(colors:[const Color(0xff8f52ff).withOpacity(.14),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(s.width*.9,s.height*.42),radius:260));
    c.drawRect(Offset.zero& s,p1); c.drawRect(Offset.zero&s,p2);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class Glass extends StatelessWidget {
  final Widget child; final EdgeInsets padding; final double radius;
  const Glass({super.key,required this.child,this.padding=const EdgeInsets.all(18),this.radius=22});
  @override Widget build(BuildContext context)=>ClipRRect(
    borderRadius:BorderRadius.circular(radius),
    child:BackdropFilter(filter:ImageFilter.blur(sigmaX:18,sigmaY:18),child:Container(
      padding:padding,
      decoration:BoxDecoration(color:const Color(0xff18213a).withOpacity(.55),borderRadius:BorderRadius.circular(radius),border:Border.all(color:Colors.white.withOpacity(.10))),
      child:child)));
}

class GlassNav extends StatelessWidget {
  final int index; final ValueChanged<int> onTap;
  const GlassNav({super.key,required this.index,required this.onTap});
  @override Widget build(BuildContext context)=>SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(18,0,18,14),child:Glass(
    padding:const EdgeInsets.symmetric(vertical:8),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
      _n(Icons.home_rounded,'Home',0),_n(Icons.check_circle_outline_rounded,'Today',1),_n(Icons.folder_open_rounded,'Projects',2),_n(Icons.insights_rounded,'Insights',3),_n(Icons.settings_rounded,'Settings',4),
    ]))));
  Widget _n(IconData icon,String label,int i)=>InkWell(onTap:()=>onTap(i),borderRadius:BorderRadius.circular(18),child:Padding(padding:const EdgeInsets.all(7),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,color:i==index?const Color(0xff38d9ff):Colors.white54,size:21),Text(label,style:TextStyle(fontSize:9,color:i==index?const Color(0xff38d9ff):Colors.white54))])));
}

class Header extends StatelessWidget {
  final String kicker,title,subtitle;
  const Header({super.key,required this.kicker,required this.title,required this.subtitle});
  @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(22,18,22,18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(kicker,style:const TextStyle(color:Color(0xff38d9ff),fontWeight:FontWeight.w700,fontSize:11,letterSpacing:1.2)),
    const SizedBox(height:5),Text(title,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.white54,fontSize:13))
  ]));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext c){final s=ChangeNotifierProvider.of(c);return ListView(children:[
    const Header(kicker:'SUNDAY · NEXA',title:'Good morning.',subtitle:'Your day, under control.'),
    Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Glass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text("TODAY'S PROGRESS",style:TextStyle(color:Colors.white54,fontSize:11,fontWeight:FontWeight.w700)),
      const SizedBox(height:6),Text('${(s.progress*100).round()}%',style:const TextStyle(fontSize:38,fontWeight:FontWeight.w700)),
      const SizedBox(height:12),ClipRRect(borderRadius:BorderRadius.circular(10),child:LinearProgressIndicator(value:s.progress,minHeight:8,color:const Color(0xff38d9ff),backgroundColor:Colors.white10)),
      const SizedBox(height:8),Text('${s.completed} / ${s.tasks.length} completed',style:const TextStyle(color:Colors.white54,fontSize:11)),
    ]))),
    const SectionTitle('UP NEXT'),
    ...s.tasks.where((t)=>!t.done).take(3).map((t)=>TaskTile(t)),
    Padding(padding:const EdgeInsets.fromLTRB(18,10,18,100),child:Glass(child:Row(children:[const Icon(Icons.auto_awesome,color:Color(0xff9b63ff)),const SizedBox(width:12),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('FOCUS MODE',style:TextStyle(color:Color(0xffb38aff),fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:3),Text('${s.tasks.where((t)=>!t.done).length} tasks waiting for your attention.',style:const TextStyle(fontWeight:FontWeight.w600))])]))),
  ]);}
}

class SectionTitle extends StatelessWidget {final String text;const SectionTitle(this.text,{super.key});@override Widget build(BuildContext c)=>const SizedBox();}

class TodayPage extends StatefulWidget {const TodayPage({super.key});@override State<TodayPage> createState()=>_TodayState();}
class _TodayState extends State<TodayPage>{String filter='ALL';String query='';
  @override Widget build(BuildContext c){final s=ChangeNotifierProvider.of(c);final list=s.tasks.where((t)=>(filter=='ALL'||filter==t.priority||(filter=='DONE'&&t.done))&&t.title.toLowerCase().contains(query.toLowerCase())).toList();return Column(children:[
    Header(kicker:'TASKS',title:'Today',subtitle:'Keep momentum without the noise.'),
    Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Search tasks',filled:true,fillColor:Colors.white.withOpacity(.05),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none)))),
    Padding(padding:const EdgeInsets.all(14),child:Row(children:['ALL','HIGH','DONE'].map((x)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x)))).toList())),
    Expanded(child:ListView(children:[...list.map((t)=>TaskTile(t)),const SizedBox(height:100)]))
  ]);}
}

class TaskTile extends StatelessWidget {
  final Task task; const TaskTile(this.task,{super.key});
  @override Widget build(BuildContext c){final s=ChangeNotifierProvider.of(c);final color=task.priority=='HIGH'?const Color(0xffff5770):const Color(0xff38d9ff);return Padding(padding:const EdgeInsets.fromLTRB(18,0,18,10),child:Dismissible(key:ValueKey(task.id),background:Container(color:Colors.red.withOpacity(.15),alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:24),child:const Icon(Icons.delete)),onDismissed:(_)=>s.remove(task),child:Glass(child:Row(children:[
    InkWell(onTap:()=>s.toggle(task),child:Container(width:24,height:24,decoration:BoxDecoration(shape:BoxShape.circle,color:task.done?const Color(0xff49e68f).withOpacity(.18):Colors.transparent,border:Border.all(color:task.done?const Color(0xff49e68f):color)),child:task.done?const Icon(Icons.check,size:16,color:Color(0xff49e68f)):null)),
    const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(task.title,style:TextStyle(fontWeight:FontWeight.w700,color:task.done?Colors.white38:Colors.white,decoration:task.done?TextDecoration.lineThrough:null)),const SizedBox(height:4),Text('${task.due} · ${task.project}',style:const TextStyle(fontSize:11,color:Colors.white54))])),if(task.priority!='NORMAL')Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:color.withOpacity(.14),borderRadius:BorderRadius.circular(99)),child:Text(task.done?'DONE':task.priority,style:TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:color)))
  ]))));}
}

class ProjectsPage extends StatelessWidget {const ProjectsPage({super.key});@override Widget build(BuildContext c){final s=ChangeNotifierProvider.of(c);return ListView(children:[const Header(kicker:'WORKSPACE',title:'Projects',subtitle:'Everything has a place.'),Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Column(children:[...s.projects.asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Glass(child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(shape:BoxShape.circle,color:[const Color(0xff38d9ff),const Color(0xff9b63ff),const Color(0xff49e68f),const Color(0xffff5770)][e.key].withOpacity(.15)),child:Icon(Icons.folder_rounded,color:[const Color(0xff38d9ff),const Color(0xff9b63ff),const Color(0xff49e68f),const Color(0xffff5770)][e.key])),const SizedBox(width:14),Expanded(child:Text(e.value,style:const TextStyle(fontWeight:FontWeight.w700))),const Icon(Icons.chevron_right,color:Colors.white38)])))),const SizedBox(height:100)]))]);}}

class InsightsPage extends StatelessWidget {const InsightsPage({super.key});@override Widget build(BuildContext c){final s=ChangeNotifierProvider.of(c);return ListView(children:[const Header(kicker:'ANALYTICS',title:'Your momentum',subtitle:'A calm view of how you work.'),Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Column(children:[
  Glass(child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('WEEKLY COMPLETION',style:TextStyle(color:Colors.white54,fontSize:11)),const SizedBox(height:5),Text('${(s.progress*100).round()}%',style:const TextStyle(fontSize:36,fontWeight:FontWeight.w700)),const Text('Live from your task history',style:TextStyle(color:Colors.white54,fontSize:11))])),const Icon(Icons.trending_up,color:Color(0xff49e68f),size:42)])),
  const SizedBox(height:12),Glass(child:const Row(children:[Icon(Icons.local_fire_department_rounded,color:Color(0xffff9f43),size:38),SizedBox(width:14),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('CURRENT STREAK',style:TextStyle(color:Colors.white54,fontSize:11)),SizedBox(height:4),Text('9 DAYS',style:TextStyle(fontSize:26,fontWeight:FontWeight.w700)),Text('Consistency compounds.',style:TextStyle(color:Colors.white54,fontSize:11))])])),
  const SizedBox(height:12),Glass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('FOCUS BREAKDOWN',style:TextStyle(color:Colors.white54,fontSize:11)),const SizedBox(height:18),_bar('Product',.48,const Color(0xff38d9ff)),_bar('Personal',.27,const Color(0xff9b63ff)),_bar('Planning',.15,const Color(0xff49e68f)),_bar('Other',.10,const Color(0xffff5770))])),
  const SizedBox(height:100)]))]);}
  Widget _bar(String n,double v,Color col)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(n),Text('${(v*100).round()}%',style:TextStyle(color:col,fontWeight:FontWeight.w700))]),const SizedBox(height:5),ClipRRect(borderRadius:BorderRadius.circular(9),child:LinearProgressIndicator(value:v,minHeight:7,color:col,backgroundColor:Colors.white10))]));}
}

class SettingsPage extends StatelessWidget {const SettingsPage({super.key});@override Widget build(BuildContext c)=>ListView(children:[const Header(kicker:'SYSTEM',title:'Settings',subtitle:'Make NEXA work your way.'),Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Column(children:[
  setting(Icons.dark_mode_rounded,'Appearance','Midnight Glass'),setting(Icons.notifications_rounded,'Notifications','Smart reminders'),setting(Icons.flag_rounded,'Default priority','Normal'),setting(Icons.calendar_today_rounded,'Week starts','Monday'),setting(Icons.auto_awesome,'AI Assist','Focus suggestions'),setting(Icons.cloud_done_rounded,'Data','Local-first sync'),const SizedBox(height:22),const Text('NEXA v1.0 · Privacy-first · Local-first',style:TextStyle(color:Colors.white30,fontSize:10)),const SizedBox(height:100)]))]);
  Widget setting(IconData icon,String a,String b)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Glass(child:Row(children:[Icon(icon,color:const Color(0xff38d9ff)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:3),Text(b,style:const TextStyle(color:Colors.white54,fontSize:11))])),const Icon(Icons.chevron_right,color:Colors.white30)])));
}

class AddTaskDialog extends StatefulWidget {const AddTaskDialog({super.key});@override State<AddTaskDialog> createState()=>_AddTaskState();}
class _AddTaskState extends State<AddTaskDialog>{
 final title=TextEditingController();String project='Personal',priority='NORMAL',due='Today',reminder='None',repeat='Does not repeat';
 @override Widget build(BuildContext c)=>Dialog(backgroundColor:Colors.transparent,child:Glass(child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('NEW TASK',style:TextStyle(color:Color(0xff38d9ff),fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:4),const Text('Create task',style:TextStyle(fontSize:27,fontWeight:FontWeight.w700)),const SizedBox(height:16),
 TextField(controller:title,autofocus:true,decoration:const InputDecoration(labelText:'Task title',hintText:'What needs to get done?')),
 const SizedBox(height:10),_dd('Project',project,['Personal','Product','Work','Design'],(v)=>setState(()=>project=v!)),
 _dd('Priority',priority,['NORMAL','HIGH'],(v)=>setState(()=>priority=v!)),
 _dd('Reminder',reminder,['None','10 min before','30 min before','1 hour before'],(v)=>setState(()=>reminder=v!)),
 _dd('Repeat',repeat,['Does not repeat','Daily','Weekly','Monthly'],(v)=>setState(()=>repeat=v!)),
 const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton(onPressed:(){if(title.text.trim().isEmpty)return;ChangeNotifierProvider.of(c).add(Task(id:DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),project:project,priority:priority,due:due,reminder:reminder,repeat:repeat));Navigator.pop(c);},child:const Text('CREATE TASK')))
 ]))));
 Widget _dd(String label,String value,List<String> items,ValueChanged<String?> fn)=>DropdownButtonFormField<String>(value:value,decoration:InputDecoration(labelText:label),items:items.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:fn);
}
