// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PrimitiveTypeUtils} from "@iden3/contracts/lib/PrimitiveTypeUtils.sol";
import {ICircuitValidator} from "@iden3/contracts/interfaces/ICircuitValidator.sol";
import {EmbeddedZKPVerifier} from "@iden3/contracts/verifiers/EmbeddedZKPVerifier.sol";

contract WhiZper is EmbeddedZKPVerifier {
    uint64 public constant TRANSFER_REQUEST_ID_SIG_VALIDATOR = 1;
    // uint64 public constant TRANSFER_REQUEST_ID_MTP_VALIDATOR = 2;

    uint public currentGroupId;
    mapping(uint => mapping(uint => bool)) public userGroupMapping;
    mapping(uint => string) public groupNameMapping;

    event Group(uint indexed groupId, uint indexed userId, string groupName);
    event Message(uint indexed groupId, uint indexed userId, string message);
    /// @custom:storage-location erc7201:polygonid.storage.ERC20Verifier
    struct WhiZperStorage {
        mapping(uint256 => address) idToAddress;
        mapping(address => uint256) addressToId;
        // uint256 TOKEN_AMOUNT_FOR_AIRDROP_PER_ID;
    }

    // keccak256(abi.encode(uint256(keccak256("polygonid.storage.ERC20Verifier")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant WhiZperStorageLocation =
        0x3b1c3bd751d9cd42a3739426a271cdc235017946663d56eeaf827d70f8b77000;

    function _getWhiZperStorage()
        private
        pure
        returns (WhiZperStorage storage $)
    {
        assembly {
            $.slot := WhiZperStorageLocation
        }
    }

    modifier beforeTransfer(address to) {
        require(
            isProofVerified(to, TRANSFER_REQUEST_ID_SIG_VALIDATOR),
            // isProofVerified(to, TRANSFER_REQUEST_ID_MTP_VALIDATOR),
            "only identities who provided sig or mtp proof for transfer requests are allowed to receive tokens"
        );
        _;
    }

    function initialize() public initializer {
        WhiZperStorage storage $ = _getWhiZperStorage();
        // super.__ERC20_init(name, symbol);
        super.__EmbeddedZKPVerifier_init(_msgSender());
        currentGroupId = 0;
        // $.TOKEN_AMOUNT_FOR_AIRDROP_PER_ID = 5 * 10 ** uint256(decimals());
    }

    function _beforeProofSubmit(
        uint64 /* requestId */,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal view override {
        // check that challenge input is address of sender
        address addr = PrimitiveTypeUtils.uint256LEToAddress(
            inputs[validator.inputIndexOf("challenge")]
        );
        // this is linking between msg.sender and
        // TODO: verify proof sender
        // require(
        //     _msgSender() == addr,
        //     "address in proof is not a sender address"
        // );
    }

    function createGroup(
        uint64 requestId,
        uint256[] calldata inputs,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint userId,
        string memory groupName
    ) public {
        super.submitZKPResponse(requestId, inputs, a, b, c);
        uint groupId = currentGroupId;
        groupNameMapping[groupId] = groupName;
        joinGroup(requestId, inputs, a, b, c, groupId, userId);
        currentGroupId++;
    }

    function joinGroup(
        uint64 requestId,
        uint256[] calldata inputs,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint groupId,
        uint userId
    ) public {
        require(
            userGroupMapping[userId][groupId] == false,
            "User has joined the group"
        );
        super.submitZKPResponse(requestId, inputs, a, b, c);
        string memory groupName = groupNameMapping[groupId];
        emit Group(groupId, userId, groupName);
        userGroupMapping[userId][groupId] = true;
    }

    function sendMessage(
        uint64 requestId,
        uint256[] calldata inputs,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint groupId,
        uint userId,
        string memory message
    ) public {
        super.submitZKPResponse(requestId, inputs, a, b, c);
        require(
            userGroupMapping[userId][groupId],
            "User has not joined the group"
        );

        emit Message(groupId, userId, message);
    }

    function _afterProofSubmit(
        uint64 requestId,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal override {
        WhiZperStorage storage $ = _getWhiZperStorage();
        if (
            requestId == TRANSFER_REQUEST_ID_SIG_VALIDATOR
            // requestId == TRANSFER_REQUEST_ID_MTP_VALIDATOR
        ) {
            // if proof is given for transfer request id ( mtp or sig ) and it's a first time we mint tokens to sender
            // uint256 id = inputs[1];
            // if ($.idToAddress[id] == address(0) && $.addressToId[_msgSender()] == 0) {
            //     super._mint(_msgSender(), $.TOKEN_AMOUNT_FOR_AIRDROP_PER_ID);
            //     $.addressToId[_msgSender()] = id;
            //     $.idToAddress[id] = _msgSender();
            // }
        }
    }

    // function _update(
    //     address from /* from */,
    //     address to,
    //     uint256 amount /* amount */
    // ) internal override beforeTransfer(to) {
    //     super._update(from, to, amount);
    // }

    // function getIdByAddress(address addr) public view returns (uint256) {
    //     return _getERC20VerifierStorage().addressToId[addr];
    // }

    // function getAddressById(uint256 id) public view returns (address) {
    //     return _getERC20VerifierStorage().idToAddress[id];
    // }

    // function getTokenAmountForAirdropPerId() public view returns (uint256) {
    //     return _getERC20VerifierStorage().TOKEN_AMOUNT_FOR_AIRDROP_PER_ID;
    // }
}
