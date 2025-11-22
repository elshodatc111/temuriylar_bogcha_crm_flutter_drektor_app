import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_items/child_davomad_page.dart';

class GroupDavomadPage extends StatefulWidget {
  final int id;
  final Map<String, dynamic> joriyOy;
  final Map<String, dynamic> otganOy;

  const GroupDavomadPage({
    super.key,
    required this.id,
    required this.joriyOy,
    required this.otganOy,
  });

  @override
  State<GroupDavomadPage> createState() => _GroupDavomadPageState();
}

class _GroupDavomadPageState extends State<GroupDavomadPage> {
  static const double nameColumnWidth = 160;
  static const double dateColumnWidth = 64;
  static const double cellHeight = 52;
  static const Color zebraA = Color(0xFFF7FDFF);
  static const Color zebraB = Colors.white;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> joriyUsers = (widget.joriyOy['user'] is List)
        ? List<dynamic>.from(widget.joriyOy['user'] as List)
        : <dynamic>[];
    final List<dynamic> joriyDates = (widget.joriyOy['data'] is List)
        ? List<dynamic>.from(widget.joriyOy['data'] as List)
        : <dynamic>[];

    final List<dynamic> otganUsers = (widget.otganOy['user'] is List)
        ? List<dynamic>.from(widget.otganOy['user'] as List)
        : <dynamic>[];
    final List<dynamic> otganDates = (widget.otganOy['data'] is List)
        ? List<dynamic>.from(widget.otganOy['data'] as List)
        : <dynamic>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Davomad'),
        actions: [
          IconButton(
            onPressed: () async {
              final res = await Get.to(() => ChildGroupDavomadPage(id: widget.id));
              if (res == true) Get.back(result: true);
            },
            icon: Icon(Icons.checklist_rtl),
          ),
          SizedBox(width: 8.0),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLegend(),
            const SizedBox(height: 12),
            const Text(
              'Joriy oy davomadi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildFullTable(joriyDates, joriyUsers),
            const SizedBox(height: 18),
            const Text(
              'Oldingi davomad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildFullTable(otganDates, otganUsers),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendItem(_statusBox('keldi'), 'Keldi'),
        _legendItem(_statusBox('kechikdi'), 'Kechikdi'),
        _legendItem(_statusBox('kelmadi'), 'Kelmadi'),
        _legendItem(_statusBox('kasal'), 'Kasal'),
        _legendItem(_statusBox('sababli'), 'Sababli'),
        _legendItem(_statusBox('false'), 'Davomad olinmagan'),
      ],
    );
  }

  Widget _legendItem(Widget icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _statusBox(String status) {
    final w = _statusIconWidget(status);
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 4),
      child: w,
    );
  }

  Widget _statusIconWidget(dynamic status) {
    final s = status?.toString().toLowerCase() ?? 'false';
    Color bg;
    Color iconColor;
    IconData icon;
    String tooltip;

    switch (s) {
      case 'keldi':
        bg = Colors.green.shade100;
        iconColor = Colors.green.shade700;
        icon = Icons.check;
        tooltip = 'Keldi';
        break;
      case 'kechikdi':
        bg = Colors.orange.shade100;
        iconColor = Colors.orange.shade700;
        icon = Icons.access_time;
        tooltip = 'Kechikdi';
        break;
      case 'kelmadi':
        bg = Colors.red.shade100;
        iconColor = Colors.red.shade700;
        icon = Icons.close;
        tooltip = 'Kelmadi';
        break;
      case 'kasal':
        bg = Colors.purple.shade100;
        iconColor = Colors.purple.shade700;
        icon = Icons.local_hospital;
        tooltip = 'Kasal';
        break;
      case 'sababli':
        bg = Colors.blue.shade100;
        iconColor = Colors.blue.shade700;
        icon = Icons.info_outline;
        tooltip = 'Sababli';
        break;
      default:
        bg = Colors.grey.shade100;
        iconColor = Colors.grey.shade600;
        icon = Icons.remove_circle_outline;
        tooltip = 'Davomad olinmagan';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: iconColor.withOpacity(0.7)),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  // Full table: left fixed column + right horizontally scrollable content
  Widget _buildFullTable(List<dynamic> dates, List<dynamic> users) {
    if (dates.isEmpty && users.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: const Text("Ma'lumot topilmadi."),
      );
    }

    final double tableWidth = nameColumnWidth + dates.length * dateColumnWidth;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: fixed column with header and all names
          Container(
            width: nameColumnWidth,
            color: Colors.blue.shade700,
            child: Column(
              children: [
                // header cell
                Container(
                  height: cellHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    'Bola / Sana',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // names column
                Container(
                  // make names list as Column inside SingleChildScrollView (vertical scrolling handled by outer)
                  color: Colors.transparent,
                  child: Column(
                    children: List.generate(users.length, (index) {
                      final u = users[index];
                      final name = u['name']?.toString() ?? '-';
                      final bg = (index % 2 == 0) ? zebraA : zebraB;
                      return Container(
                        height: cellHeight,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Text(name, style: const TextStyle(fontSize: 14)),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // RIGHT: horizontally scrollable area (dates header + rows of status icons)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: tableWidth - nameColumnWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dates header row
                    Container(
                      height: cellHeight,
                      color: Colors.blue.shade700,
                      child: Row(
                        children: dates.map<Widget>((d) {
                          return Container(
                            width: dateColumnWidth,
                            height: cellHeight,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              d?.toString() ?? '-',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // rows
                    Column(
                      children: List.generate(users.length, (rowIdx) {
                        final u = users[rowIdx];
                        final List<dynamic> statusList = (u['status'] is List)
                            ? List<dynamic>.from(u['status'] as List)
                            : <dynamic>[];
                        final bg = (rowIdx % 2 == 0) ? zebraA : zebraB;

                        return Container(
                          color: bg,
                          child: Row(
                            children: List.generate(dates.length, (colIdx) {
                              final status = colIdx < statusList.length
                                  ? statusList[colIdx]
                                  : 'false';
                              return Container(
                                width: dateColumnWidth,
                                height: cellHeight,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: _statusIconWidget(status),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
