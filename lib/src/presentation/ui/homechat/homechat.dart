import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:polygonid_flutter_sdk_example/src/data/secure_storage.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/navigations/routes.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/ui/chat/chat_arg.dart';
import 'package:web3dart/web3dart.dart';

class HomeChat extends StatefulWidget {
  const HomeChat({Key? key}) : super(key: key);

  @override
  _HomeChatState createState() => _HomeChatState();
}

class _HomeChatState extends State<HomeChat> {
  List<Map<String, String>> _groups = [];

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, String>> userGroups = [];
  String? _polygonId;

  @override
  void initState() {
    _loadIdentity();
    super.initState();
    _loadUserGroups();
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

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString('assets/abi.json');
    await dotenv.load(fileName: ".env");
    String contractAddress = dotenv.env['CONTRACT_ADDRESS']!;

    final contract = DeployedContract(
      ContractAbi.fromJson(abi, 'WhiZper'),
      EthereumAddress.fromHex(contractAddress),
    );

    return contract;
  }

  Future<Map<String, dynamic>> request(String query) async {
    final url = Uri.parse(
        'https://api.studio.thegraph.com/query/82798/whizper-sepolia/v0.0.3');

    final response = await post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': query,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _loadUserGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _groups.clear(); // Clear existing groups to avoid duplication
    });

    try {
      await _loadIdentity();
      if (_polygonId == null) {
        throw Exception('Private key is null');
      }

      userGroups = [];
      BigInt polygonIdBigInt = BigInt.parse(_polygonId!, radix: 16);
      final response = await request(
          "{groups(where:{userId:\"${polygonIdBigInt.toString()}\"}){userId groupId groupName}}");
      final logs = response['data']['groups'];

      for (var log in logs) {
        String groupId = log["groupId"];
        String groupName = log["groupName"];
        String userId = log["userId"];

        BigInt polygonIdBigInt = BigInt.parse(_polygonId!, radix: 16);
        if (userId == polygonIdBigInt.toString()) {
          userGroups.add({
            "userId": userId,
            "groupId": groupId,
            "groupName":
                groupName, // Replace with actual group name retrieval logic
          });
        }
      }

      setState(() {
        _groups = userGroups;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user groups: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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
    body: Stack(
      children: [
        // Background image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Main content
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isLoading ? 'Loading...' : ''),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_errorMessage'),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadUserGroups,
                              child: Text('Retry'),
                            ),
                          ],
                        )
                      : userGroups.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('No groups found.'),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _loadIdentity();
                                    await _loadUserGroups();
                                  },
                                  child: Text('Search Groups'),
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: _groups.length,
                              separatorBuilder: (context, index) => Divider(),
                              itemBuilder: (context, index) {
                                final group = _groups[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.chatPath,
                                      arguments: Chat_arg(
                                        userId: group["userId"]!,
                                        groupId: group["groupId"]!,
                                        groupName: group["groupName"] ?? "Default Group Name",
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: ListTile(
                                      title: Center(child: Text(group["groupName"]!)),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ],
    ),
  );
}
}
