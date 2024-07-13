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

  final _addGroupFormKey = GlobalKey<FormState>();
  final _joinGroupFormKey = GlobalKey<FormState>();
  final _groupIdController = TextEditingController();

  String _addGroupName = '';
  String? _joinGroupId = '';
  BigInt polygonIDB = BigInt.zero;

  // Mock ZK proof
  BigInt requestId = BigInt.parse("1");
  List<BigInt> inputs = [
    BigInt.parse('1'),
    BigInt.parse(
        '23148936466334350744548790012294489365207440754509988986684797708370051073'),
    BigInt.parse(
        '1496222740463292783938163206931059379817846775593932664024082849882751356658'),
    BigInt.parse(
        '2943483356559152311923412925436024635269538717812859789851139200242297094'),
    BigInt.parse('32'),
    BigInt.parse('583091486781463398742321306787801699791102451699'),
    BigInt.parse(
        '2330632222887470777740058486814238715476391492444368442359814550649181604485'),
    BigInt.parse(
        '21933750065545691586450392143787330185992517860945727248803138245838110721'),
    BigInt.parse('1'),
    BigInt.parse(
        '2943483356559152311923412925436024635269538717812859789851139200242297094'),
    BigInt.parse('1642074362')
  ];
  List<BigInt> a = [
    BigInt.parse(
        '1586737020434671186479469693201682903767348489278928918437644869362426285987'),
    BigInt.parse(
        '10368374578954982886026700668192458272023628059221185517094289432313391574346')
  ];
  List<List<BigInt>> b = [
    [
      BigInt.parse(
          '10467634573017180218197884581733108252303484275914626793162330699221056049997'),
      BigInt.parse(
          '8209584930734522176349491274051519385730056242274029221348202709658022380255')
    ],
    [
      BigInt.parse(
          '16780462512570391766527074671395013717949680440025828249250261266320709865031'),
      BigInt.parse(
          '8727203460568364282837439956284542723424467542192739359133672824842743578575')
    ]
  ];
  List<BigInt> c = [
    BigInt.parse(
        '11215761237716692384931356337281938111805620146858403764487216970162196454846'),
    BigInt.parse(
        '4563515138436312174368382548605579502301781805108297754551533822937265670041')
  ];


  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }



  Future<void> _createGroup(polygonId, String groupName) async {
    try {
      setState(() => _isLoading = true);
      await dotenv.load(fileName: ".env");
      String apiUrl = dotenv.env['PROVIDER']!;
      var httpClient = Client();
      var ethClient = Web3Client(apiUrl, httpClient);

      await dotenv.load(fileName: ".env");
      String privateKey =
          dotenv.env['PRIVATE_KEY']!; // Define the privateKey variable

      Credentials credentials = EthPrivateKey.fromHex("0x" + privateKey);
      final contract = await loadContract();
      final function = contract.function('createGroup');

      BigInt polygonIdBigInt = BigInt.parse(polygonId, radix: 16);
      polygonIDB = polygonIdBigInt;

      await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: function,
          parameters: [
            requestId,
            inputs,
            a,
            b,
            c,
            polygonIdBigInt,
            groupName
          ], // Ensure this matches the smart contract's expected types
        ),
        chainId: 11155111,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created: $groupName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitAddGroupForm() async {
    if (_addGroupFormKey.currentState!.validate()) {
      _addGroupFormKey.currentState!.save();
      await _createGroup(_polygonId, _addGroupName);
      _addGroupFormKey.currentState!.reset();
    }
  }


Widget _buildAddGroupForm() {
    return Form(
      key: _addGroupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Group',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Group Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a group name';
              }
              return null;
            },
            onSaved: (value) {
              _addGroupName = value!;
            },
          ),
          SizedBox(height: 8.0),
          ElevatedButton(
            child: Text('Add Group'),
            onPressed: _isLoading ? null : _submitAddGroupForm,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('WhiZper'),
      actions: [

        IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {
              // Implement QR code scan functionality here
              // For example: widget._bloc.add(const AuthEvent.clickScanQrCode());
            },
          ),
        IconButton(
          icon: Icon(Icons.add),
            onPressed: () async {
            await showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.all(50.0),
                child: _buildAddGroupForm(),
              );
              },
            );
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
