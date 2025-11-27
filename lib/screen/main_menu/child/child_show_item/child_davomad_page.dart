import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class ChildDavomadPage extends StatefulWidget {
  final int id;
  const ChildDavomadPage({super.key, required this.id});

  @override
  State<ChildDavomadPage> createState() => _ChildDavomadPageState();
}

class _ChildDavomadPageState extends State<ChildDavomadPage> {
  List<dynamic> childData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChildDavomad();
  }

  Future<void> fetchChildDavomad() async {
    final url = Uri.parse("${ApiConst.apiUrl}/child-show-davomad/${widget.id}");

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer ${GetStorage().read('token')}", 
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        childData = json["data"];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator(backgroundColor: Colors.white,color: Colors.blue,))
        : childData.isEmpty?Center(child: Text("Davomad tarixi mavjud emas."),):ListView.builder(
      itemCount: childData.length,
      itemBuilder: (context, index) {
        final item = childData[index];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
            side: BorderSide(color: Colors.blue)
          ),
          margin: EdgeInsets.only(top: 0,bottom: 4,right: 0,left: 0),
          child: ListTile(
            title: Text("asd",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600),),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,size: 14,color: Colors.blue,),
                    SizedBox(width: 4,),
                    Text(item['data'])
                  ],
                ),

                Row(
                  children: [
                    Icon(Icons.type_specimen_outlined,size: 14,color: Colors.blue,),
                    SizedBox(width: 4,),
                    Text(item['status'])
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
