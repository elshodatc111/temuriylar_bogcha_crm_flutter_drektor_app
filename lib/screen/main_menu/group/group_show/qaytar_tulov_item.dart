import 'package:flutter/material.dart';
class QaytarTulovItem extends StatefulWidget {
  List<dynamic> qaytar;
  QaytarTulovItem({super.key, required this.qaytar});

  @override
  State<QaytarTulovItem> createState() => _QaytarTulovItemState();
}

class _QaytarTulovItemState extends State<QaytarTulovItem> {
  @override
  Widget build(BuildContext context) {
    return Text("Qaytarilgan to'lovlar Tayyorlanmoqda.");
  }
}
