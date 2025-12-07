import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/chart/pages/kunlik_davomad_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/chart/pages/kunlik_tulov_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/chart/pages/moliya_chart_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/chart/pages/oylik_davomad_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/chart/pages/oylik_tulov_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/chart/pages/tarbiyachi_reyting_page.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Statistika")),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                Get.to(() => KunlikDavomadPage());
              },
              child: _itemMenu(
                "Kunlik davomad",
                Icons.today,
              ), // 📅 Kunlik davomad
            ),

            InkWell(
              onTap: () {
                Get.to(() => OylikDavomadPage());
              },
              child: _itemMenu(
                "Oylik davomad",
                Icons.calendar_month,
              ), // 🗓 Oylik davomad
            ),

            InkWell(
              onTap: () {
                Get.to(() => TarbiyachiReytingPage());
              },
              child: _itemMenu(
                "Tarbiyachilar reyting",
                Icons.workspace_premium,
              ), // 🏅 Reyting
            ),

            InkWell(
              onTap: () {
                Get.to(() => KunlikTulovPage());
              },
              child: _itemMenu(
                "Kunlik to'lovlar",
                Icons.payments,
              ), // 💵 Kunlik to'lovlar
            ),

            InkWell(
              onTap: () {
                Get.to(() => OylikTulovPage());
              },
              child: _itemMenu(
                "Oylik to'lovlar",
                Icons.account_balance_wallet,
              ), // 💳 Oylik to'lovlar
            ),

            InkWell(
              onTap: () {
                Get.to(() => MoliyaChartPage());
              },
              child: _itemMenu(
                "Moliya statistikasi",
                Icons.show_chart,
              ), // 📈 Moliya statistikasi
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemMenu(String title, IconData icon) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.blue, width: 1.2),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}
