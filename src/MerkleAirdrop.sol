//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {Test , console} from "../lib/forge-std/src/Test.sol";


contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    // some list of address
    // Allow someone in the list to claim tokens
    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdroptoken;
    mapping(address => bool) private s_claimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    // merkle proofs -> Its a gas efficient way to know if a data is present in the list , looping through the list might cause gas insuffiency

    event Claim(address, uint256);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop","1") {
        i_merkleRoot = merkleRoot;
        i_airdroptoken = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof , uint8 v , bytes32 r , bytes32 s) external {
        if (s_claimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        console.log('REACHED HERE SUCCESS 1');
        if (!_isValidSignature(account,getMessageHash(account,amount),v,r,s)) {
            console.log('SIGNATURE FAIL');
            revert MerkleAirdrop__InvalidSignature();
        }
        console.log('REACHED HERE SUCCESS 2');
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        console.log("CLAIMER->",account);
        console.log("GAS PAYER->",msg.sender);
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        console.log('REACHED HERE SUCCESS 3');
        s_claimed[account] = true;

        emit Claim(account, amount);

        i_airdroptoken.safeTransfer(account, amount);
    }

    function getMessageHash(address account , uint256 amount) public view returns(bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(MESSAGE_TYPEHASH,AirdropClaim({account:account , amount:amount}))
            )
        );
    }

    function getMerkleRoot() public view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() public view returns (IERC20) {
        return i_airdroptoken;
    }

    function _isValidSignature(address account , bytes32 digest ,uint8 v,bytes32 r,bytes32 s) internal pure returns(bool) {
        (address actualSignature , ,) = ECDSA.tryRecover(digest , v, r,s);
        console.log("ACTUAL",actualSignature);
        console.log("ACCOUNT", account);
        return (actualSignature == account);
    }
}
