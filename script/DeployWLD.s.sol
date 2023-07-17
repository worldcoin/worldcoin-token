pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {WLD} from "src/WLD.sol";

contract DeployWLD is Script {

    WLD public token;
    address[] holders;
    uint256[] amounts;
    uint256 inflationCapPeriodInit;
    uint256 inflationCapWadInit;
    uint256 inflationLockPeriodInit;

    function run() external {
        vm.startBroadcast();

        // 1.5% yearly inflation starting 15 years after launch
        inflationCapPeriodInit = 2628000;       // 1 month, 30 days 10 hours.
        inflationCapWadInit = 1241487716449316; // ceil[((1.015)^(1/12) - 1) * 10**18]
        inflationLockPeriodInit = 2163542400;   // 15 years, 2038-07-24 00:00:00 UTC

        // Import initial holders from old contract
        holders = [
            address(uint160(0x008155ef75b9ccaff88a6d247b2beaf30903397f4b)),
            address(uint160(0x008c93ee3c6ec37de3292df35b4bfdaed6a693fa16)),
            address(uint160(0x00adbd670b7f9b337d013db341c30db9f60b6bbe63)),
            address(uint160(0x00fd1eee3d93d624ccb8e5aa06c735b2c58c1cfd29)),
            address(uint160(0x004631dd875942ff2eb32a3da2ec07c16ca8224908)),
            address(uint160(0x006d16e3fd2dabffca19ce4dca9a7ce343efa57d9a)),
            address(uint160(0x00ef3ab52c9f7b13332d90a0b3aa4d56233d62e4d1)),
            address(uint160(0x0078a6d7b78ecaf05c842d75af31772f26dcf46935)),
            address(uint160(0x00fc28bcabfd9ad2b5ada7f482f9bba6df1446623a)),
            address(uint160(0x00e9223215fd4d21de7ff187b6987576ca352f0bb3)),
            address(uint160(0x000c6f9f3a757bf1a5552821aad011d5ff5d03ba20)),
            address(uint160(0x007277d122e65b209cbb455a230c36c85b3fd9947e)),
            address(uint160(0x00920fcb7ba09e97daff210ad46e093d755554e7a7)),
            address(uint160(0x00d7c95a54e20be5bcac1ae11b81129ec74922d13c)),
            address(uint160(0x008306a9d7ea6fbc0a64b279a66b95b8d670e79592)),
            address(uint160(0x002825fe488da71285a5736c7ae2c21a35446d3225)),
            address(uint160(0x009080083e2327aad13a38a179049aed1d12f00791)),
            address(uint160(0x0002a7fe8b3178c7b7a94d6124b81400dc15ca9a7c)),
            address(uint160(0x0017115e584748e23e3890acef2c08658fdb24527d)),
            address(uint160(0x0059bbca737ae0a7e5d2ecb91b07c1b19ea612f52e)),
            address(uint160(0x0039473e9b41da09396eae3bf87f7e28f19049ab14)),
            address(uint160(0x00f9a0cd0aab52e4b6edcb52388085ff0237b159e4)),
            address(uint160(0x0049a405dfc24d39bfae3f369e8b17328b0c55fa2c)),
            address(uint160(0x008c08294dfaba1f3a482c0bfdd8880a429164989d)),
            address(uint160(0x00d01a40c59ef84f2b295eb18006a278eaefb24a3e)),
            address(uint160(0x0046d377c4116dd1e9a3d7fb84a52763b9780fcc21)),
            address(uint160(0x0045852d52fc45419f67aede1b1553409bb4169fa5)),
            address(uint160(0x000d0a3e9680d7dd7baf71ca6fa17366766c3eabe5)),
            address(uint160(0x00a7349586da2048125ad7f214269aa91cae7c9408)),
            address(uint160(0x005b9112f95ad564ee5df62de749264b3ce48f899d)),
            address(uint160(0x00f5578cece5fec43f932e4b51adb81da545d3caaa)),
            address(uint160(0x00b61b9d41ff6e3240c0f6f8b79cbd9a671b41914b)),
            address(uint160(0x00b8d0c56f206c2faf1257a2e0cec016c87e2f4b3d)),
            address(uint160(0x0084f1c513379088705ed3a9da743505cd932bd855)),
            address(uint160(0x009589b2c136bb86cfcabec536d72729379cd9b46d)),
            address(uint160(0x001bdf56836dd524fb49d9c9e871794f850f2dc37e)),
            address(uint160(0x005bef5e814abeb88c449addbd3c1a31488a8ee00a)),
            address(uint160(0x002a2e53a4f503c453311865e076752f557d09dff2)),
            address(uint160(0x006d7bc43f6643441d1cbe3b432a9336dd2ae76bc7)),
            address(uint160(0x0059d9ab9c68ef7357de1b96de91ce7c8f14bb8fe8)),
            address(uint160(0x003255a865848255b428ca24f0b03fd0f8d93559a2)),
            address(uint160(0x00a9ad1ea2027c741322a3761266f4affeeb9b3de4)),
            address(uint160(0x00e617254e8c16d2ef9900284fb8ac48496e2fffc3)),
            address(uint160(0x00128eca5e9fa3c3d556197df4e82ef12315865c11)),
            address(uint160(0x003be95be03dc8e22c287c045d1e92cfc8ad8b3be4)),
            address(uint160(0x00d7ab4a54e2d99d3b979506f6469179ff555f1025)),
            address(uint160(0x00b7c7bada3bfd0e359f1688e01779861c1523787d)),
            address(uint160(0x0063f4566e966f4b8affd3be878b292fdf219db9fd)),
            address(uint160(0x00d252fcf298450f93ce2e64c8da11fc71231d0771)),
            address(uint160(0x000fd3af73d34d2a18e56195e2589a1231206dbef2)),
            address(uint160(0x0052edfe063ab3ba9ec0de11a44e3d35338c531e56)),
            address(uint160(0x00d9d30c8eb0923fe778b3372b3f511d8223d339cd)),
            address(uint160(0x00641813a0a19deeda4e251aff40dfeaa85333bb2d)),
            address(uint160(0x00848bfd0e34c580610385b004fe4b267b41ab97d7)),
            address(uint160(0x000065b237ab86384de32331df8ae5a46463729830)),
            address(uint160(0x0037eeefc1b2ccf2ac6291f3be9f8aac1ca6e0a7a7)),
            address(uint160(0x0085925f9b06a244c746fca8c8b289333699c25bad)),
            address(uint160(0x00687fbc6f6a0d34bf07772e503e3765af900fb828)),
            address(uint160(0x008ad4f7eb4eae409e458119174266c8ff2f8d7aa9)),
            address(uint160(0x00f8e24ac99420f6576e136b570fd879ca6356721e)),
            address(uint160(0x005bfa1da3eec1bc64fa5c162dde8763af3ffb09c7)),
            address(uint160(0x000595a90011d65c33b2eb794fd19600a958579728)),
            address(uint160(0x002a790327168cc34c607af02923d5a0b60c37ab0a)),
            address(uint160(0x002f37aab4808d3cc985d868d516b48d63ec0834b0)),
            address(uint160(0x00911e0945cf9f44a1adb242490058f7d55e0782ad))
        ];
        
        // Import initial balances from old contract
        amounts = [
            uint256(1656555000),
            uint256(125000000),
            uint256(55000),
            uint256(100000),
            uint256(450000),
            uint256(1000000),
            uint256(500000),
            uint256(350000),
            uint256(50000000),
            uint256(1000000),
            uint256(2500000),
            uint256(4000000),
            uint256(2500000),
            uint256(750000),
            uint256(1000000),
            uint256(50000000),
            uint256(150000),
            uint256(650000),
            uint256(50000),
            uint256(2500000),
            uint256(100000),
            uint256(1000000),
            uint256(500000),
            uint256(500000),
            uint256(1000000),
            uint256(750000),
            uint256(500000),
            uint256(25000),
            uint256(100000),
            uint256(5000000),
            uint256(3000000),
            uint256(150000),
            uint256(180000),
            uint256(100000),
            uint256(600000),
            uint256(16500000),
            uint256(1000000),
            uint256(1000000),
            uint256(950000),
            uint256(250000000),
            uint256(1500000),
            uint256(4500000),
            uint256(150000),
            uint256(1500000),
            uint256(30000000),
            uint256(4000000),
            uint256(500000),
            uint256(280000),
            uint256(2500000),
            uint256(3000000),
            uint256(50000000),
            uint256(10000000),
            uint256(100000),
            uint256(2000000),
            uint256(15000000),
            uint256(30000),
            uint256(10000000),
            uint256(75000),
            uint256(800000),
            uint256(175000000),
            uint256(800000),
            uint256(600000),
            uint256(2500000),
            uint256(2500000),
            uint256(600000)
        ];

        new WLD(
            holders,
            amounts,
            "Worldcoin Token",
            "WLD",
            inflationCapPeriodInit,
            inflationCapWadInit,
            inflationLockPeriodInit
        );

        vm.stopBroadcast();
    }
}