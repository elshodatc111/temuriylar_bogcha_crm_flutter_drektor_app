import 'package:flutter/material.dart';
class ChildShowPage extends StatefulWidget {
  final int id;
  final String name;
  const ChildShowPage({super.key, required this.id, required this.name});

  @override
  State<ChildShowPage> createState() => _ChildShowPageState();
}

class _ChildShowPageState extends State<ChildShowPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
    );
  }
}
