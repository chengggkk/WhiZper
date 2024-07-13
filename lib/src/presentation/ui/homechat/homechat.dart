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
      await dotenv.load(fileName: ".env");
      String apiUrl = dotenv.env['PROVIDER']!;
      var httpClient = Client();
      var ethClient = Web3Client(apiUrl, httpClient);
      final contract = await loadContract();
      final groupEvent = contract.event("Group");

      final filter = FilterOptions.events(
        contract: contract,
        event: groupEvent,
        fromBlock: const BlockNum.exact(6299058),
        toBlock: const BlockNum.current(),
      );
final logs = await ethClient.getLogs(filter);

      userGroups = [];

      for (var log in logs) {
        final decoded = groupEvent.decodeResults(log.topics!, log.data!);
        String groupId = decoded[0].toString();
        String groupName = decoded[2].toString();
        String userId = decoded[1].toString();

        BigInt polygonIdBigInt = BigInt.parse(_polygonId!, radix: 16);
        if (userId == polygonIdBigInt.toString()) {
          userGroups.add({
            "userId": userId,
            "groupId": groupId,
            "groupName": groupName, // Replace with actual group name retrieval logic
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

        body: Column(
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
                              return ListTile(
                                title: Center(child: Text(group["groupName"]!)),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    Routes.chatPath,
                                    arguments: Chat_arg(
                                      userId: group["userId"]!,
                                      groupId: group["groupId"]!,
                                      groupName: group["groupName"] ??
                                          "Default Group Name",
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}