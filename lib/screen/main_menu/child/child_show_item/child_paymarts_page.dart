import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_create_paymart.dart';
class ChildPaymartsPage extends StatefulWidget {
  final int id;
  const ChildPaymartsPage({super.key, required this.id});

  @override
  State<ChildPaymartsPage> createState() => _ChildPaymartsPageState();
}

class _ChildPaymartsPageState extends State<ChildPaymartsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity, // 🔵 butun kenglik
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              "Yangi to'lov kiritish",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              final res = await Get.to(() => ChildCreatePaymart(id: widget.id),);
              if (res == true) {
                //_fetchDocument();
              }
            },
          ),
        )

      ],
    );
  }
}
