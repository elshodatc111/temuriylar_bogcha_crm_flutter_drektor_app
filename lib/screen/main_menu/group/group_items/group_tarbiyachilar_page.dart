import 'package:flutter/material.dart';
class GroupTarbiyachilarPage extends StatefulWidget {
  final List<dynamic> tarbiyachilar;
  const GroupTarbiyachilarPage({super.key, required this.tarbiyachilar});

  @override
  State<GroupTarbiyachilarPage> createState() => _GroupTarbiyachilarPageState();
}

class _GroupTarbiyachilarPageState extends State<GroupTarbiyachilarPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guruh tarbiyachilar"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){}, icon: Icon(Icons.person_add_alt_1_outlined))
        ],
      ),
    );
  }
}
