import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/davomad/davomad_creatre_page.dart';

final String baseUrl = ApiConst.apiUrl;

class KunlikHodimDavomadiPage extends StatefulWidget {
  const KunlikHodimDavomadiPage({super.key});

  @override
  State<KunlikHodimDavomadiPage> createState() =>
      _KunlikHodimDavomadiPageState();
}

class _KunlikHodimDavomadiPageState extends State<KunlikHodimDavomadiPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _joriyOy;
  Map<String, dynamic>? _otganOy;
  late TabController _tabController;
  AttendanceDataSource? _dataSource;

  // O'zbek oy nomlari
  static const Map<int, String> _oyNomi = {
    1: "Yanvar",
    2: "Fevral",
    3: "Mart",
    4: "Aprel",
    5: "May",
    6: "Iyun",
    7: "Iyul",
    8: "Avgust",
    9: "Sentabr",
    10: "Oktyabr",
    11: "Noyabr",
    12: "Dekabr",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // listen tab changes to rebuild datasource
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _prepareDataSource();
        setState(() {});
      }
    });
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final box = GetStorage();
    final token = box.read('token');
    if (token == null) return null;
    return token.toString();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _error = 'Token topilmadi. Iltimos tizimga kiring.';
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/emploes-davomad-history');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        setState(() {
          _joriyOy = body['joriy_oy'] as Map<String, dynamic>?;
          _otganOy = body['otgan_oy'] as Map<String, dynamic>?;
          _isLoading = false;
        });
        _prepareDataSource();
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) msg = b['message'].toString();
        } catch (_) {}
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'So‘rovda xatolik: $e';
        _isLoading = false;
      });
    }
  }

  void _prepareDataSource() {
    final map = _tabController.index == 0 ? _joriyOy : _otganOy;
    if (map == null) {
      setState(() {
        _dataSource = AttendanceDataSource([], []);
      });
      return;
    }

    final List<String> dates = (map['dates'] as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    final employeesRaw = map['employees'] as List<dynamic>? ?? [];
    final List<EmployeeAttendance> rows = employeesRaw.map((e) {
      final id = e['id'];
      final name = e['name'] ?? '';
      final statusesRaw = e['statuses'] as List<dynamic>? ?? [];
      final statuses = statusesRaw.map((s) {
        if (s == null) return 'false';
        return s.toString();
      }).toList();
      return EmployeeAttendance(id: id, name: name, statuses: statuses);
    }).toList();
    setState(() {
      _dataSource = AttendanceDataSource(dates, rows);
    });
  }

  // Format: "25-Noyabr" (kun - oy nomi)
  String _headerDayMonth(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    final day = dt.day;
    final monthName = _oyNomi[dt.month] ?? dt.month.toString();
    return '$day-$monthName';
  }

  // legend widget
  Widget _legendItem(Color bg, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 10, backgroundColor: bg, child: Icon(icon, size: 12, color: Colors.black54)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color headerBlue = Colors.blue;
    final Color headerTextColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hodimning davomadi'),
        backgroundColor: headerBlue,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: headerBlue,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: headerTextColor,
              unselectedLabelColor: Colors.grey.shade300,
              tabs: const [
                Tab(text: 'Joriy oy davomadi'),
                Tab(text: "O'tgan oy davomadi"),
              ],
              onTap: (i) {},
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Get.to(() => DavomadCreatrePage());

              if (result == true) {
                _fetchData();
              }
            },
            icon: const Icon(Icons.fact_check),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta yuklash'),
              ),
            ],
          ),
        ),
      )
          : _buildGridArea(),
    );
  }

  Widget _buildGridArea() {
    final map = _tabController.index == 0 ? _joriyOy : _otganOy;
    if (map == null) {
      return const Center(child: Text('Ma\'lumot topilmadi'));
    }
    final dates = (map['dates'] as List<dynamic>).map((e) => e.toString()).toList();
    if (_dataSource == null || _dataSource!.dates.length != dates.length) {
      _prepareDataSource();
    }

    final Color headerBlue = Colors.blue;
    final headerTextStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    // build columns
    final List<GridColumn> columns = [];
    columns.add(
      GridColumn(
        columnName: 'name',
        width: 180,
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.centerLeft,
          color: headerBlue,
          child: const Text(
            'FIO / Data',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );

    for (final d in dates) {
      final header = _headerDayMonth(d); // <- "25-Noyabr" format
      columns.add(
        GridColumn(
          columnName: d,
          width: 92,
          label: Container(
            padding: const EdgeInsets.all(6),
            alignment: Alignment.center,
            color: headerBlue,
            child: Text(header, style: headerTextStyle.copyWith(fontSize: 12)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Colors.blue.shade700),
        ),
        child: Column(
          children: [
            // header legend area (blue background, white text)
            Container(
              width: double.infinity,
              color: headerBlue,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _legendItem(Colors.green.shade100, Icons.check_circle, 'Keldi'),
                  _legendItem(Colors.orange.shade100, Icons.check_circle_outline, 'Formasiz keldi'),
                  _legendItem(Colors.amber.shade100, Icons.access_time, 'Kechikdi'),
                  _legendItem(Colors.red.shade100, Icons.close, 'Kelmadi'),
                  _legendItem(Colors.lightBlue.shade100, Icons.local_hospital, 'Kasal'),
                  _legendItem(Colors.grey.shade300, Icons.info_outline, 'Sababli'),
                  _legendItem(Colors.grey.shade300, Icons.block, 'Ish kuni emas'),
                ],
              ),
            ),

            // small spacing between legend and grid
            const SizedBox(height: 8),

            // grid area with zebra rows
            Expanded(
              child: SfDataGrid(
                source: _dataSource!,
                columns: columns,
                columnWidthMode: ColumnWidthMode.none,
                gridLinesVisibility: GridLinesVisibility.both,
                headerGridLinesVisibility: GridLinesVisibility.both,
                allowPullToRefresh: true,
                verticalScrollPhysics: const AlwaysScrollableScrollPhysics(),
                selectionMode: SelectionMode.none,
                rowHeight: 44,
                frozenColumnsCount: 1,
                horizontalScrollPhysics: const BouncingScrollPhysics(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Model: one employee attendance row
class EmployeeAttendance {
  final int id;
  final String name;
  final List<String> statuses;

  EmployeeAttendance({
    required this.id,
    required this.name,
    required this.statuses,
  });
}

/// DataSource for SfDataGrid
class AttendanceDataSource extends DataGridSource {
  final List<String> dates;
  final List<EmployeeAttendance> employees;

  AttendanceDataSource(this.dates, this.employees) {
    buildDataGridRows();
  }

  List<DataGridRow> _dataGridRows = [];

  void buildDataGridRows() {
    _dataGridRows = employees.map<DataGridRow>((r) {
      final List<DataGridCell> cells = [];
      // name cell
      cells.add(DataGridCell<String>(columnName: 'name', value: r.name));
      // status cells
      for (int i = 0; i < dates.length; i++) {
        final s = (i < r.statuses.length) ? r.statuses[i] : 'false';
        cells.add(DataGridCell<String>(columnName: dates[i], value: s));
      }
      return DataGridRow(cells: cells);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  // Build row UI with zebra (alternating) background colors
  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final List<Widget> widgets = [];
    final cells = row.getCells();

    for (var cell in cells) {
      if (cell.columnName == 'name') {
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Text(
              cell.value?.toString() ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      } else {
        final status = cell.value?.toString() ?? 'false';
        widgets.add(
          Container(
            alignment: Alignment.center,
            child: _statusIconWidget(status),
          ),
        );
      }
    }

    // determine row index for zebra (fallback to 0 if not found)
    final int index = _dataGridRows.indexOf(row);
    final Color evenColor = Colors.white;
    final Color oddColor = Colors.blue.shade50.withOpacity(0.35); // subtle blue
    final Color rowColor = (index % 2 == 0) ? evenColor : oddColor;

    return DataGridRowAdapter(color: rowColor, cells: widgets);
  }

  // status -> icon widget (no label, tooltip only)
  Widget _statusIconWidget(String status) {
    final s = status;
    Color bg = Colors.grey.shade200;
    IconData icon = Icons.help_outline;
    String tooltip = s;

    switch (s) {
      case 'keldi':
      case 'formada_keldi':
      case 'keldi_true':
        bg = Colors.green.shade100;
        icon = Icons.check_circle;
        tooltip = 'Keldi';
        break;
      case 'formasiz_keldi':
        bg = Colors.orange.shade100;
        icon = Icons.check_circle_outline;
        tooltip = 'Formasiz keldi';
        break;
      case 'kechikdi':
        bg = Colors.amber.shade100;
        icon = Icons.access_time;
        tooltip = 'Kechikdi';
        break;
      case 'kelmadi':
      case 'false':
        bg = Colors.red.shade100;
        icon = Icons.close;
        tooltip = 'Kelmadi';
        break;
      case 'kasal':
        bg = Colors.lightBlue.shade100;
        icon = Icons.local_hospital;
        tooltip = 'Kasal';
        break;
      case 'sababli':
        bg = Colors.grey.shade300;
        icon = Icons.info_outline;
        tooltip = 'Sababli';
        break;
      case 'ish_kuni_emas':
        bg = Colors.grey.shade200;
        icon = Icons.block;
        tooltip = 'Ish kuni emas';
        break;
      default:
        if (s.contains('form')) {
          bg = Colors.green.shade100;
          icon = Icons.check_circle;
          tooltip = 'Keldi';
        } else {
          bg = Colors.grey.shade200;
          icon = Icons.help_outline;
          tooltip = s;
        }
    }

    return Tooltip(
      message: tooltip,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: bg,
        child: Icon(icon, size: 16, color: Colors.black54),
      ),
    );
  }
}
