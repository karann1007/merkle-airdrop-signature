//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {Test , console} from "../lib/forge-std/src/Test.sol";
import {MerkleAirdrop} from '../src/MerkleAirdrop.sol';
import {BagelToken} from '../src/BagelToken.sol';
import {DevOpsTools} from '../lib/foundry-devops/src/DevOpsTools.sol';
import {DeployMerkleAirdrop} from '../script/DeployMerkleAirdrop.s.sol';
import {ZkSyncChainChecker} from '../lib/foundry-devops/src/ZkSyncChainChecker.sol';

contract MerkleAirdropTest is Test , ZkSyncChainChecker {

    MerkleAirdrop public airdrop ;
    BagelToken public token;
    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user ;
    uint256 userPrivKey;
    address public gaspayer ;

    uint256 public constant AMOUNT = 25 * 1e18;
    uint256 public constant AMOUNT_TO_SEND = AMOUNT * 4 ;

    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne , proofTwo];

    function setUp() public {
        if(!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            ( airdrop , token ) = deployer.deployMerkleAirdrop();
        } else {
            token = new BagelToken();
            airdrop = new MerkleAirdrop(ROOT , token);
            token.mint( token.owner() , AMOUNT * 4);
            token.transfer(address(airdrop) , AMOUNT_TO_SEND);
            console.log("AIRDROP BALANCE" , token.balanceOf(address(airdrop)));
        }
        (user , userPrivKey) = makeAddrAndKey("user");
        gaspayer = makeAddr("gaspayer");
    } 

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = airdrop.getMessageHash(user,AMOUNT);

        // vm.prank(user);
        // sign a message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey , digest);

        //gaspayer calls claim using the user's signature
        vm.prank(gaspayer);
        airdrop.claim(user , AMOUNT , PROOF , v , r,s);

        uint256 endingBalance = token.balanceOf(user);

        console.log("ENDING BALANCE", endingBalance);

        assertEq(endingBalance - startingBalance ,  AMOUNT);
    }
}
