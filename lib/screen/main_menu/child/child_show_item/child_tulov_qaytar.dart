import 'package:flutter/material.dart';
class ChildTulovQaytar extends StatefulWidget {
  final int id;
  const ChildTulovQaytar({super.key, required this.id});

  @override
  State<ChildTulovQaytar> createState() => _ChildTulovQaytarState();
}

class _ChildTulovQaytarState extends State<ChildTulovQaytar> {
  @override
  Widget build(BuildContext context) {
    return Text("Tulovni qaytarish");
  }
}
