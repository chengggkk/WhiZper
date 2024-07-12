import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:polygonid_flutter_sdk_example/src/data/secure_storage.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/navigations/routes.dart';
import 'package:web3dart/web3dart.dart';

class HomeChat extends StatefulWidget {
  const HomeChat({Key? key}) : super(key: key);

  @override
  _HomeChatState createState() => _HomeChatState();
}

class _HomeChatState extends State<HomeChat> {


  String? _polygonId;


  @override
  void initState() {
    _loadIdentity();
    super.initState();
  }

  Future<void> _loadIdentity() async {
    try {
      _polygonId = await SecureStorage.read(
          key: 'privateKey'); // Replace with your key name
      setState(() {});
    } catch (e) {
      print('Error loading private key: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
                title: const Text('WhiZper'),
                actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              Navigator.pushNamed(context, Routes.addAndJoinPath);
            },
          ),
        ],
        ),
    );
  }
}