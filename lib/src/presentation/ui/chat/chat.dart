import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:polygonid_flutter_sdk_example/src/data/secure_storage.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/ui/chat/chat_arg.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Chat extends StatefulWidget {
  final Chat_arg chatArguments;

  const Chat({Key? key, required this.chatArguments}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  String? _polygonId;
  List<Map<String, dynamic>> messages = [];
  TextEditingController _messageController = TextEditingController();
  late Web3Client _client;
  late DeployedContract _contract;
  late ContractFunction _sendMessage;
  late ContractFunction _getMessages;
  bool _isWeb3Initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWeb3();
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

  Future<void> _loadMessages() async {


      try {
      await _loadIdentity();
      await dotenv.load(fileName: ".env");
      String apiUrl = dotenv.env['PROVIDER']!;
      var httpClient = Client();
      var ethClient = Web3Client(apiUrl, httpClient);
      final contract = await loadContract();
      final messageEvent = contract.event("Message");

      final filter = FilterOptions.events(
        contract: contract,
        event: messageEvent,
        fromBlock: const BlockNum.exact(6299058),
        toBlock: const BlockNum.current(),
      );
final logs = await ethClient.getLogs(filter);

      messages = [];

      for (var log in logs) {
        final decoded = messageEvent.decodeResults(log.topics!, log.data!);
        String groupId = decoded[0].toString();
        String message = decoded[2].toString();
        String userId = decoded[1].toString();

        BigInt polygonIdBigInt = BigInt.parse(_polygonId!, radix: 16);
        if (userId == polygonIdBigInt.toString()) {
          messages.add({
            "userId": userId,
            "groupId": groupId,
            "message": message, // Replace with actual group name retrieval logic
          });
        }
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
      final credentials = EthPrivateKey.fromHex(_polygonId!);
      await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: _sendMessage,
          parameters: [
            BigInt.from(widget.chatArguments.groupId as num),
            BigInt.from(widget.chatArguments.userId as num),
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
                  child: ListView.separated(
                    itemCount: messages.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index)
                     {
                      final message = messages[index];
                      return ListTile(
                        title: Text(message["message"]!),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
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
                          _messageController.clear();
                        },
                        child: Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
