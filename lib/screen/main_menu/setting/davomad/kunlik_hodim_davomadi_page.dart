import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/davomad/davomad_creatre_page.dart';
class KunlikHodimDavomadiPage extends StatefulWidget {
  const KunlikHodimDavomadiPage({super.key});

  @override
  State<KunlikHodimDavomadiPage> createState() => _KunlikHodimDavomadiPageState();
}

class _KunlikHodimDavomadiPageState extends State<KunlikHodimDavomadiPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hodimning davomadi"),
        actions: [
          IconButton(onPressed: (){
            Get.to(()=>DavomadCreatrePage());
          }, icon: Icon(Icons.fact_check))
        ],
      ),
    );
  }
}
