import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/ChildWidget/active_child_widget.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/ChildWidget/all_child_widget.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/ChildWidget/debet_child_widget.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/ChildWidget/end_child_widget.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/create_child_page.dart';

class ChildPage extends StatelessWidget {
  const ChildPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Bolalar"),
          actions: [
            IconButton(
              onPressed: () {
                Get.to(() => const CreateChildPage());
              },
              icon: const Icon(Icons.add_circle_outline),
              tooltip: "Yangi bola qo'shish",
            ),
            const SizedBox(width: 8.0),
          ],
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: Colors.white,
            indicatorWeight: 1.0,
            labelColor: Colors.white,
            labelStyle: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w400),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.list_alt),text: "Barchasi",),
              Tab(icon: Icon(Icons.account_balance_wallet),text: "Qarzdorlar",),
              Tab(icon: Icon(Icons.check_circle),text: "Aktiv",),
              Tab(icon: Icon(Icons.group_off),text: "Guruhsiz",),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(0.0),
          child: const TabBarView(
            children: [
              AllChildWidget(),
              DebetChildWidget(),
              ActiveChildWidget(),
              EndChildWidget()
            ],
          ),
        ),
      ),
    );
  }
}

