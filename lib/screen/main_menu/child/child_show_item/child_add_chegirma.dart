import 'package:flutter/material.dart';
class ChildAddChegirma extends StatefulWidget {
  final int id;
  const ChildAddChegirma({super.key, required this.id});

  @override
  State<ChildAddChegirma> createState() => _ChildAddChegirmaState();
}

class _ChildAddChegirmaState extends State<ChildAddChegirma> {
  @override
  Widget build(BuildContext context) {
    return Text("Chegirma kiritish");
  }
}
