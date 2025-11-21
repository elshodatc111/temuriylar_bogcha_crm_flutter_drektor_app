import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/hodim_page.dart';
import 'package:temuriylar_crm_app_admin/screen/profile/profile_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sozlamalar")),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
              children: [
                _itemMenu(Icons.person,"Profil","Profil ma'lumotlari",(){Get.to(()=>ProfilePage());}),
                _itemMenu(Icons.add,"Hodimlar","Hodimlar sozlamalari",(){Get.to(()=>HodimPage());}),
                _itemMenu(Icons.add,"Xonalar","Xonalar sozlamalari",(){print('Xonalar');}),
                _itemMenu(Icons.add,"Lavozimlar","Mavjud lavozimlar",(){print('Lavozimlar');}),
                _itemMenu(Icons.add,"SMS","SMS sozlamalari",(){print('Hodimlar');}),
                _itemMenu(Icons.add,"To'lovlar","To'lov sozlamalari",(){print('Hodimlar');}),
                _itemMenu(Icons.add,"Moliya","Moliya hisoboti",(){print('Hodimlar');}),
                _itemMenu(Icons.add,"Statistika","Statistika",(){print('Hodimlar');}),
              ]
          ),
        ),
      ),
    );
  }
  Widget _itemMenu(IconData icon, String title, String subtitle, VoidCallback onTab){
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)),side: BorderSide(color: Colors.blue,width: 0.5)),
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon,color: Colors.blue.shade300,),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right,color: Colors.blue.shade400,size: 24,),
        onTap: onTab,
      ),
    );
  }
}
