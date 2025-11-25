import 'package:flutter/material.dart';
class IshHaqiItems extends StatefulWidget {
  final List<dynamic> ishHaqi;
  const IshHaqiItems({super.key, required this.ishHaqi});

  @override
  State<IshHaqiItems> createState() => _IshHaqiItemsState();
}

class _IshHaqiItemsState extends State<IshHaqiItems> {
  @override
  Widget build(BuildContext context) {
    return Text("Hodimlar ish haqi Tayyorlanmoqda");
  }
}
