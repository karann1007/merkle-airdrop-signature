//SPDX-License-Identifier
pragma solidity ^0.8.24;

import {Script}  from '../lib/forge-std/src/Script.sol';
import {BagelToken} from '../src/BagelToken.sol';
import {MerkleAirdrop} from '../src/MerkleAirdrop.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract DeployMerkleAirdrop is Script {
    MerkleAirdrop merkleAirdrop;
    BagelToken token ;
    bytes32 private s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant AMOUNT_MINTED = 4 * 25 * 1e18;
    uint256 private constant AMOUNT_TO_AIRDROP = 25 * 1e18;

    function deployMerkleAirdrop() public returns(MerkleAirdrop ,  BagelToken) {
        vm.startBroadcast();
        token = new BagelToken();
        merkleAirdrop = new MerkleAirdrop( s_merkleRoot, IERC20(address(token)));
        token.mint(token.owner() , AMOUNT_MINTED);
        token.transfer(address(merkleAirdrop) , AMOUNT_TO_AIRDROP);
        vm.stopBroadcast();
        return (merkleAirdrop , token);
    }
    function run() external returns (MerkleAirdrop , BagelToken) {
        return deployMerkleAirdrop();
    }
}