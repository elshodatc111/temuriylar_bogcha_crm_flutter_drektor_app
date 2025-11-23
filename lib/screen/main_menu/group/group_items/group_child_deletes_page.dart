import 'package:flutter/material.dart';
class GroupChildDeletesPage extends StatefulWidget {
  final List<dynamic> list;
  const GroupChildDeletesPage({super.key, required this.list});

  @override
  State<GroupChildDeletesPage> createState() => _GroupChildDeletesPageState();
}

class _GroupChildDeletesPageState extends State<GroupChildDeletesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guruhdan o'chirlilganlar"),
      ),
    );
  }
}
