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
        'https://api.studio.thegraph.com/query/82798/whizper-sepolia/v0.0.1');

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

      final response = await request("{messages(where: { groupId: $groupId }){userId groupId message}}");

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
          parameters: [bigIntGroupId, bigIntUserId, message],
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
