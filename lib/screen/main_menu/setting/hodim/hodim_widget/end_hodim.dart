import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/hodim_show_page.dart';

final String baseUrl = ApiConst.apiUrl;

class EndHodim extends StatefulWidget {
  const EndHodim({super.key});

  @override
  State<EndHodim> createState() => _EndHodimState();
}

class _EndHodimState extends State<EndHodim> {
  final GetStorage _storage = GetStorage();
  String? _token;
  bool _isLoading = false;
  String _error = '';
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    final t = _storage.read('token');
    if (t != null && t is String && t
        .trim()
        .isNotEmpty) {
      _token = t;
    } else {
      _token = null;
    }
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = 'Token topilmadi. Iltimos qayta login qiling.';
        _employees = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/emploes-end');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );
      print(resp.statusCode);
      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final List<dynamic> users = body['users'] ?? body['data'] ?? [];

        final List<Employee> list = users.map((e) {
          if (e is Map<String, dynamic>) return Employee.fromJson(e);
          return Employee.fromJson(Map<String, dynamic>.from(e));
        }).toList();

        if (mounted) {
          setState(() {
            _employees = list;
            _isLoading = false;
          });
        }
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) msg = b['message'].toString();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _error = msg;
            _employees = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'So‘rovda xatolik: $e';
          _employees = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text("Ma'lumotlar yuklanmoqda..."),
        ],
      ),
    )
        : _error.isNotEmpty
        ? Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchEmployees,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta yuklash'),
            ),
          ],
        ),
      ),
    )
        : RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        children: [
          if (_employees.isEmpty) ...[
            SizedBox(height: 60),
            Center(
              child: Text(
                "Hodimlar topilmadi",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ] else
            ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _employees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) =>
                    _EmployeeCard(employee: _employees[index]),
              ),
            ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class Employee {
  final int id;
  final String name;
  final String phone;
  final String position;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.position,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Employee(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;

  const _EmployeeCard({Key? key, required this.employee}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.blue.shade700;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue, width: 0.5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: primary.withOpacity(0.12),
          child: Text(
            employee.name.isNotEmpty
                ? employee.name[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          employee.phone,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
            employee.position=='admin'?'Admin'
                : employee.position=='direktor'?"Drektor"
                : employee.position=='metodist'?"Metodist"
                : employee.position=='metodist'?"Metodist"
                : employee.position=='meneger'?"Menejer"
                : employee.position=='tarbiyachi'?"Tarbiyachi"
                : employee.position=='yordam_tarbiyachi'?"Yordamchi\ntarbiyachi"
                : employee.position=='psixolog'?"Psixolog"
                : employee.position=='hamshira'?"Hamshira"
                : employee.position=='logoped'?"Logoped"
                : employee.position=='defektolog'?"Defektolog"
                : employee.position=='ingliz_tili'?"Ingliz tili"
                : employee.position=='rus_tili'?"Rus tili"
                : employee.position=='jismoniy_tarbiya'?"Jismoniy\nTarbiya"
                : employee.position=='rasm_sanat'?"Rasm\nSanat"
                : employee.position=='qorovul'?"Qarovul"
                : employee.position=='bosh_oshpaz'?"Bosh oshpaz"
                : employee.position=='yordam_oshpaz'?"Yordamchi\nOshpaz"
                : employee.position=='farrosh'?"Farrosh"
                : employee.position=='kir_yuvuvchi'?"Kir yuvuvchi"
                : employee.position=='smm_muhandis'?"SMM\nmuhandis"
                : employee.position=='fotograf'?"Fotograf"
                : employee.position=='texnik'?"Texnik\nHodim"
                : employee.position=='marketing_muhandis'?"Marketing\nMuhandis":""
        ),
        onTap: (){
          Get.to(()=>HodimShowPage(id: employee.id));

        },
      ),
    );
  }
}
