import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:polygonid_flutter_sdk_example/src/data/secure_storage.dart';
import 'package:web3dart/web3dart.dart';

class AddAndJoin extends StatefulWidget {
  @override
  _AddAndJoinState createState() => _AddAndJoinState();
}

class _AddAndJoinState extends State<AddAndJoin> {
  final _addGroupFormKey = GlobalKey<FormState>();
  final _joinGroupFormKey = GlobalKey<FormState>();
  final _groupIdController = TextEditingController();

  String _addGroupName = '';
  String? _joinGroupId = '';
  bool _isLoading = false;
  String? _polygonId;
  BigInt polygonIDB = BigInt.zero;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
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
  String? contractAddress = dotenv.env['CONTRACT_ADDRESS'];
  

  if (contractAddress == null) {
    throw Exception('CONTRACT_ADDRESS not found in .env file');
  }

  final contract = DeployedContract(
    ContractAbi.fromJson(abi, 'Pulongggon'),
    EthereumAddress.fromHex(contractAddress),
  );

  return contract;
}
  Future<void> _createGroup(polygonId, String groupName) async {
    try {
      setState(() => _isLoading = true);
      await dotenv.load(fileName: ".env");
      String apiUrl = dotenv.env['PROVIDER']!;
      var httpClient = Client();
      var ethClient = Web3Client(apiUrl, httpClient);

      await dotenv.load(fileName: ".env");
      String privateKey = dotenv.env['PRIVATE_KEY']!; // Define the privateKey variable

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Management $polygonIDB'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAddGroupForm(),
                    SizedBox(height: 16.0),
                  ],
                ),
              ),
      ),
    );
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
}
