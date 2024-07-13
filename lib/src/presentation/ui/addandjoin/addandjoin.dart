import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:polygonid_flutter_sdk_example/src/data/secure_storage.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/dependency_injection/dependencies_provider.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/navigations/routes.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/ui/common/widgets/feature_card.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/ui/home/home_bloc.dart';
import 'package:polygonid_flutter_sdk_example/src/presentation/ui/home/home_state.dart';
import 'package:polygonid_flutter_sdk_example/utils/custom_strings.dart';
import 'package:web3dart/web3dart.dart';

class AddAndJoin extends StatefulWidget {
  @override
  _AddAndJoinState createState() => _AddAndJoinState();
}

class _AddAndJoinState extends State<AddAndJoin> {
  final _addGroupFormKey = GlobalKey<FormState>();
  final _joinGroupFormKey = GlobalKey<FormState>();
  final _groupIdController = TextEditingController();

  late final HomeBloc _bloc;

  String _addGroupName = '';
  String? _joinGroupId = '';
  bool _isLoading = false;
  String? _polygonId;
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
  void initState() {
    _bloc = getIt<HomeBloc>();
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
      ContractAbi.fromJson(abi, 'WhiZper'),
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

  Widget _buildAuthenticateFeatureCard() {
    return BlocBuilder(
      bloc: _bloc,
      builder: (BuildContext context, HomeState state) {
        bool enabled = (state is! LoadingDataHomeState) &&
            (state.identifier != null && state.identifier!.isNotEmpty);
        return FeatureCard(
          methodName: CustomStrings.authenticateMethod,
          title: CustomStrings.authenticateTitle,
          description: CustomStrings.authenticateDescription,
          onTap: () {
            Navigator.pushNamed(context, Routes.authPath);
          },
        );
      },
    );
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
                    _buildAuthenticateFeatureCard(),
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
