import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:polygonid_flutter_sdk_example/src/data/secure_storage.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/ui/chat/chat_arg.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'dart:convert';

class Chat extends StatefulWidget {
  final Chat_arg chatArguments;

  const Chat({Key? key, required this.chatArguments}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  String groupId = '';
  String userId = '';

  String? _polygonId;
  List<Map<String, dynamic>> messages = [];
  TextEditingController _messageController = TextEditingController();
  late Web3Client _client;
  late DeployedContract _contract;
  late ContractFunction _sendMessage;
  late ContractFunction _getMessages;
  bool _isWeb3Initialized = false;

  late BigInt bigIntGroupId;
  late BigInt bigIntUserId;

  // Mock ZK proof
  BigInt requestId = BigInt.parse("1");
  List<BigInt> inputs = [
    BigInt.parse('1'),
    BigInt.parse('23148936466334350744548790012294489365207440754509988986684797708370051073'),
    BigInt.parse('1496222740463292783938163206931059379817846775593932664024082849882751356658'),
    BigInt.parse('2943483356559152311923412925436024635269538717812859789851139200242297094'),
    BigInt.parse('32'),
    BigInt.parse('583091486781463398742321306787801699791102451699'),
    BigInt.parse('2330632222887470777740058486814238715476391492444368442359814550649181604485'),
    BigInt.parse('21933750065545691586450392143787330185992517860945727248803138245838110721'),
    BigInt.parse('1'),
    BigInt.parse('2943483356559152311923412925436024635269538717812859789851139200242297094'),
    BigInt.parse('1642074362')
  ];
  List<BigInt> a = [
    BigInt.parse('1586737020434671186479469693201682903767348489278928918437644869362426285987'),
    BigInt.parse('10368374578954982886026700668192458272023628059221185517094289432313391574346')
  ];
  List<List<BigInt>> b = [
    [
      BigInt.parse('10467634573017180218197884581733108252303484275914626793162330699221056049997'),
      BigInt.parse('8209584930734522176349491274051519385730056242274029221348202709658022380255')
    ],
    [
      BigInt.parse('16780462512570391766527074671395013717949680440025828249250261266320709865031'),
      BigInt.parse('8727203460568364282837439956284542723424467542192739359133672824842743578575')
    ]
  ];
  List<BigInt> c = [
    BigInt.parse('11215761237716692384931356337281938111805620146858403764487216970162196454846'),
    BigInt.parse('4563515138436312174368382548605579502301781805108297754551533822937265670041')
  ];

  @override
  void initState() {
    super.initState();
    _initializeWeb3();
    groupId = widget.chatArguments.groupId;
    userId = widget.chatArguments.userId;
    bigIntGroupId = BigInt.parse(groupId, radix: 16);
    bigIntUserId = BigInt.parse(userId);
  }

  Future<void> _initializeWeb3() async {
    try {
      await dotenv.load(fileName: ".env");
      String? rpcUrl = dotenv.env['PROVIDER'];
      if (rpcUrl == null) {
        throw Exception('RPC_URL not found in .env file');
      }
      _client = Web3Client(rpcUrl, Client());
      _contract = await loadContract();
      _sendMessage = _contract.function('sendMessage');
      await _loadIdentity();
      await _loadMessages();
      setState(() {
        _isWeb3Initialized = true;
      });
    } catch (e) {
      print('Error initializing Web3: $e');
    }
  }

  Future<void> _loadIdentity() async {
    try {
      _polygonId = await SecureStorage.read(key: 'privateKey');
    } catch (e) {
      print('Error loading private key: $e');
    }
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString('assets/abi.json');
    String? contractAddress = dotenv.env['CONTRACT_ADDRESS'];
    if (contractAddress == null) {
      throw Exception('CONTRACT_ADDRESS not found in .env file');
    }
    return DeployedContract(
      ContractAbi.fromJson(abi, 'WhiZper'),
      EthereumAddress.fromHex(contractAddress),
    );
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

  Future<void> _loadMessages() async {
    try {
      await _loadIdentity();
      await dotenv.load(fileName: ".env");
      String apiUrl = dotenv.env['PROVIDER']!;
      var httpClient = Client();
      var ethClient = Web3Client(apiUrl, httpClient);
      final contract = await loadContract();
      final messageEvent = contract.event("Message");

      final response = await request(
          "{messages(where: { groupId: $groupId }){userId groupId message}}");

      final logs = response['data']['messages'];

      for (var log in logs) {
        String groupId = log["groupId"];
        String message = log["message"];
        String userId = log["userId"];

        BigInt polygonIdBigInt = BigInt.parse(_polygonId!, radix: 16);
        // if (userId == polygonIdBigInt.toString()) {
        messages.add({
          "userId": userId,
          "groupId": groupId,
          "message": message, // Replace with actual group name retrieval logic
        });
        // }
      }
    } catch (e) {
      print('Error loading user groups: $e');
    }
  }

  Future<void> _sendMessageToContract(String message) async {
    if (_polygonId == null) {
      print('Private key not loaded');
      return;
    }
    try {
      await dotenv.load(fileName: ".env");
      String apiUrl = dotenv.env['PROVIDER']!;
      var httpClient = Client();
      var ethClient = Web3Client(apiUrl, httpClient);

      await dotenv.load(fileName: ".env");
      String privateKey =
          dotenv.env['PRIVATE_KEY']!; // Define the privateKey variable

      Credentials credentials = EthPrivateKey.fromHex("0x" + privateKey);
      print('Sending message: $bigIntGroupId, $userId, $message');
      await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: _sendMessage,
          parameters: [
            requestId,
            inputs,
            a,
            b,
            c,
            bigIntGroupId,
            bigIntUserId,
            message
          ],
        ),
        chainId: 11155111,
      );
      await _loadMessages();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatArguments.groupName),
      ),
      body: _isWeb3Initialized
          ? Column(
              children: <Widget>[
                Text('User ID: ${widget.chatArguments.userId}'),
                Text('Group ID: ${widget.chatArguments.groupId}'),
                Expanded(
                  child: messages.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            bool isUserMessage = message["userId"] == userId;

                            return Align(
                              alignment: isUserMessage
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 15.0),
                                margin: EdgeInsets.symmetric(
                                    vertical: 5.0, horizontal: 8.0),
                                decoration: BoxDecoration(
                                  color: isUserMessage
                                      ? Colors.blue
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Text(
                                  message["message"]!,
                                  style: TextStyle(
                                    color: isUserMessage
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                _buildAddMessageForm(),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildAddMessageForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.0),
          ElevatedButton(
            onPressed: () async {
              await _sendMessageToContract(_messageController.text);
            },
            child: Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
