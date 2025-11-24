import 'package:flutter/material.dart';
class ChildDavomadPage extends StatefulWidget {
  final int id;
  const ChildDavomadPage({super.key, required this.id});

  @override
  State<ChildDavomadPage> createState() => _ChildDavomadPageState();
}

class _ChildDavomadPageState extends State<ChildDavomadPage> {
  @override
  Widget build(BuildContext context) {
    return Text("Bola davomadi");
  }
}
