import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/create_group_page.dart';
class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guruhlar"),
        actions: [
          IconButton(onPressed: (){Get.to(()=>CreateGroupPage());}, icon: Icon(Icons.add_circle_outline)),
          SizedBox(width: 8.0,)
        ],
      ),
    );
  }
}
