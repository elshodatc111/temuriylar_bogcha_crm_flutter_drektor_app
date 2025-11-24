import 'package:flutter/material.dart';
class ChegirmaItems extends StatefulWidget {
  final List<dynamic> chegirma;
  ChegirmaItems({super.key, required this.chegirma});

  @override
  State<ChegirmaItems> createState() => _ChegirmaItemsState();
}

class _ChegirmaItemsState extends State<ChegirmaItems> {
  @override
  Widget build(BuildContext context) {
    return Text("Chegirmlar Tayyorlanmoqda");
  }
}
