import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_page.dart';
class QaytarTulovItem extends StatefulWidget {
  List<dynamic> qaytar;
  QaytarTulovItem({super.key, required this.qaytar});

  @override
  State<QaytarTulovItem> createState() => _QaytarTulovItemState();
}
String _formatCurrency(int value) {
  final f = NumberFormat.decimalPattern('uz');
  return '${f.format(value)} UZS';
}
class _QaytarTulovItemState extends State<QaytarTulovItem> {
  @override
  Widget build(BuildContext context) {
    return widget.qaytar.isEmpty?Center(
      child: Text("Qaytarilgan to'lovlar mavjud emas."),
    ):ListView.builder(
      itemCount: widget.qaytar.length,
      itemBuilder: (ctx, index){
        final bola = widget.qaytar[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 0.0,vertical: 4.0),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
            side: BorderSide(color: Colors.blue,width: 0.5)
          ),
          child: ListTile(
            title: Row(
              children: [
                Icon(Icons.child_care,size: 16,color: Colors.blue,),
                SizedBox(width: 4.0,),
                Text(bola['child'])
              ],
            ),
            subtitle: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.grey, thickness: 1, height: 16),
                Row(
                  children: [
                    Icon(Icons.people_alt_outlined,size: 16,color: Colors.blue,),
                    SizedBox(width: 4.0,),
                    Text(bola['relative'])
                  ],
                ),
                SizedBox(height: 2,),
                Row(
                  children: [
                    Icon(Icons.payment,size: 16,color: Colors.blue,),
                    SizedBox(width: 4.0,),
                    Text("Qaytarildi:"),
                    SizedBox(width: 4.0,),
                    Text("${_formatCurrency(bola['amount'])}")
                  ],
                ),
                SizedBox(height: 2,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline,size: 16,color: Colors.blue,),
                        SizedBox(width: 4.0,),
                        Text(bola['meneger'])
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_outlined,size: 16,color: Colors.blue,),
                        SizedBox(width: 4.0,),
                        Text(bola['data'])
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 2,),
                Text(bola['about'])
              ],
            ),
            onTap: (){
              Get.to(()=>ChildShowPage(id: bola['child_id'], name: bola['child']));
            },
          ),
        );
      },
    );
  }
}
