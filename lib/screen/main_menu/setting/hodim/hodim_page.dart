import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/create_hodim_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/hodim_widget/active_hodim.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/hodim_widget/end_hodim.dart';

class HodimPage extends StatefulWidget {
  const HodimPage({super.key});

  @override
  State<HodimPage> createState() => _HodimPageState();
}

class _HodimPageState extends State<HodimPage> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hodimlar'),
          elevation: 1,
          bottom: TabBar(
            indicatorWeight: 3,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),
            tabs: [
              Tab(
                icon: const Icon(Icons.check_circle),
                text: 'Aktiv hodimlar',
              ),
              Tab(
                icon: const Icon(Icons.person_off),
                text: "Bo'shatilgan hodimlar",
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Hodim qo\'shish',
              onPressed: () {
                Get.to(()=>CreateHodimPage());
              },
              icon: const Icon(Icons.person_add_alt_1),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TabBarView(
            children: [
              ActiveHodim(),
              EndHodim(),
            ],
          ),
        ),
      ),
    );
  }
}
