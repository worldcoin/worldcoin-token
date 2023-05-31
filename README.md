# worldcoin-token

Smart contracts for the WLD token.

```bash
# Install dependencies
foundryup # install and update foundry (https://book.getfoundry.sh/getting-started/installation)
make install

yarn global add ts-node typescript # to run script to generate mock data

# Compile contracts
make build
```

Deploy to local blockchain:

```bash
# Create mock data and create config for deployment script
make mock-config
```

On a separate terminal, run a local blockchain:

```bash
anvil --mnemonic $MNEMONIC
```

Duplicate `.env.example` into `.env` and populate with correct information. Subsequently run:

```bash
source .env
```

Manually convert mock data to constructor arguments and feed it to `forge create` via the `--constructor-args` flag:

```bash
forge create --constructor-args 10000000000 1 1 "[0xD2f6b8CD528545597597D469e26695f1996619d2,0x4c6A1aDeF557d4d0181016F47085c3B6033bce56,0xCc98376f9fce378644176a68a43d4465c499c97E,0x6d3975d5b3c16B2167F405caE41cf4a9d44d9467,0x68ef11cc3083B011532B55Bd2b3A6A9bA2D6E0EE,0x28B45d1bcB1bbE960F2A0BaD5dA0D7c121249c05,0xdD7AFEa6E258663c606983b8831791Eeb6367c26,0x157163aBB5CB65fAB9C0b167F2b09c625AceDE86,0xe1BA47e7B729E4E2DfC3976FB9007Edf41BF45E9,0xe4e95B73B92499635C3357B287E8C755b7e60805,0x1B76E6E12C5f3314D5f35f1B6C4136B89181836b,0x37dF8Af0E1BFDBc5ae2297830FACdD4A11aed196,0x7b8C0b34e5F9077e89bC36D168B72D53c420d366,0x5D3C564ac772802f33aa97d2033252062d0A80B7,0x4f46B0ED1b0782dF3FE1fA2E20A93935Ae894404,0x9f8c60d885e3957118437E27Cb27C13F937b5271,0xaA7A49B4c31F31a54eb6a91ee2D5D06eFF18F989,0xd53eDfc622bFe29d9d4B1617799A68b0b805718c,0x83dC5Ad804B833c1ba94389403D675d1Dd263274,0x4311BeacDF2b567ac26930fF9193Ff3E86e7Da6e,0x29ce70673d44A2A5d860aac204B05669e0a538F6,0x9f219455a66578822c7ca7Ede4cAafC677f027fc,0xf0Db89EE78d69953B5f309E71DF98d2915C2518E,0xbC0845c5926d8e45ffEdE41022eD03971c4430a2,0x54CD84C4c309f018301d7FB00D88190C2CD2bBa7,0x07862E75785834eD4F3fCAe6eC097c85e4aB8FBb,0xc8BEED469200ecBb4E139993f6cD25e4CDdFE638,0x41662e2b82A17ec4De7710e2433a35FD0aD6484E,0x6A1D3E634eF74DA7E851F765Cff97Cf8eFbf5acb,0x8213Ee70a0dE1d78D680d0dcCe6a2C2a56aba738,0xD9FCa6de8D7E2b29a1B6e0BDA589efEf7ef34C47,0x3FFF9A069Dff8252d9Be95283b9fA8b5aef7075F,0x83cAda81B0ab354f8140898805f08c5a38468742,0xB12C726d1Acb1AAaF4ecfc6dad04646FDf7887b2,0x28170dC1C33FAfDabfdA14243F3cb147e80056D2,0x57E0DA8A73FFc1412cB858333788b56914922d58,0xF5ffdCF9662Dc30F936C8FA34c49D992F31dCE68,0x9042210d2A0c4b802c7c0CF05a569a0740283400,0x157995E5311f4cBB75b20d6485cDac752e204e0C,0xFb299c27e349f2D6617172Db6c779070b633b272,0x3810198ca58F85DF9578b1B19bA7542A4C6Fe2B8,0x6E733664886dF2FABbFfa6eaB8C3120A52933c24,0x2Bd28Ae6799fbdA79e1209503Ce8bAf61C03D95d,0xFf5c157995D3B6b980e349D96ECE5BEE3eebeB81,0x680eBa53bfD7476f10D8287fec5f6D648F41ce3B,0x079351670558f299FB55E748Cc460D70B9b251a8,0x8C567a233aF1871B2c61eC1E2488b69F02585051,0x6F270c70473867332E4b41D15CeAe79b9F65E1CE,0xc9E6057617eF6DB735eac09Ca8Ee186f91dC4a57,0x9f09Cdf6bbc68938ED83d264BDB2Dd57B5E85bD1,0xb9Ff8AA4D43b9991b339D72A90B66438569eC001,0x800f5510d94F197FE1771206eE7667F49FFEa50c,0xAB04251A2ec4a352a320025c1696D4718248008C,0x4561cF44Fbd2bB31838f27c8a76AD052211971E8,0xC7a9A79d5461330969250FB5635387eeC14Dc3AD,0xCD3522BC38AA239600cBF7160FF133BE8898ffb6,0x345deCE0128FC422ec87cB2e8f89d64Ed66333E0,0x3CB09C3db511A413467dcbf83aA2E96535c4dA11,0x30cB9B8bcD80a56EfF5f13B6E7Ef08E1d45Ad897,0x7019665B6Cf400E3FcD332c6c84758401fD7E0A6,0xB7c7785582bFE57b35693400670D0F0897CB47e4,0x676Be0968Be4f0F04cfd580de73AfF3Fc3598b91,0x8a4fF2686d0A420c7c6989D16d6Ad720fb669201,0x52eD0e9baB651eF72dDf494aD251b2afc3BDbd72,0xD3219c18152fCFc8946454ec44e4d3B27D24CCB2,0x5082Fad78F3f2dEC0dD9D1E789acDEE7f45ad073,0x1f694BFC357458dAAb952685c72d56b39A84Fd37,0xA636E0318f0d60169A752DcB880254E136Fdc122,0x91a064De7Ff3e2CFBA98099463c8E534C6BcD051,0x9bc97538FE8D8e218E61e006f4350D0357a686F7,0xFae65fa17037D8Ec90d28867768e18EEC6B4553c,0x70380b23D6FB0132A8eE9F741617A0F1aA809F95,0xA2aa8156e6e487694526A965F95EC905fd05964b,0x6081252e32D33504A83E3D9428F61D2cb93D9C40,0x334C4BC6eF2F494AF832fA634dEa39F81335Cff3,0xdD6e10C0fC933E22b1013773f0813bcB7A72e357,0x77D451C9068Aaf7d7acA825B87664A12775e42E8,0xe137e10c326932463F37ced7Bb9d4F97c20cc1E5,0xEDf8F6b42AfCE270fFaDa66eb034e4c30D3545Da,0x87D0D363C5af2845bcA93b670DD864A92736055B,0x23d2680B13766388376E39E4e6e8A343Cc692767,0x8dfBbf054772309eab64158a12f56c7E43e1aC4d,0x19958C67E0C29B00AD2354513e8B65Cdc25Aae84,0x7C64283f5Aa621d1412eD1C68f55B25Ad236811f,0x0b1FEc90Cdd93709E5162472aA33219079CD9AdF,0x22cDC9978DA5caF6859728d3cC956051C110430d,0x054c6F5CC1B9047019De26E3Fd4ee10493Ed5C19,0x8d3B8e0dD678d62742FB8e2D285bF37c26325779,0xAB65725A1EAf0963f902876D3B5c3ADf77924122,0x090a3a5337C1A419468110B53E96b50d6c6c76f1,0xa3C20771e60C21b1B1d11BB8919C1F6cccA9E1f8,0x9AAF60dCb0223FEeca89dF3f56F0E988Ed1Ca013,0x167712ED8Fe668e929dF17E7014708672FFc4c1F,0xa31bD70E255A79C81543b49D17e15BAb81F33a05,0x32373F4C46717A8370e0185e2a45b5B50af682c4,0x391be3dc22fe17caf088476B47faD00367ab9b44,0x9481cFb2A7eEC6D2119395d6fb81915c0161B62e,0x7e832343a22D041F04f72D9D05bb6516713e87A7,0xe7E90e4D98a53953da37831DcD1a25F65b92853B,0x7a220DDa44C7e61f3a0925E94EDED5Df87940BF5,0xC39C67c9B53f4bdAE51c2566e952E339f69a71aD,0x3a4804c53C256BdDfC6C5c827C30b81A6a53cd5E,0x9658E0DB5E22d53C6d87E5E897fF4478587Ed3e4,0xdFe0BF3f83ace2f6A038dF1e505b11702F65c30F,0xc5a4F0c4F2BF3E9115eD13A323cDE7cBbF8d185f,0x4510525Fc40313d3C9CcCfEbD8a08C6E8aE59154,0x5629E75D157A216A0C7F6c0869c4005cB42cfe6F,0xf48fE7fC14359a5eDA23C1576d5f6DdbD064B4Db,0xA760F80292501EA7962f27851449779A546468a2,0x15C787c7675C34CF42489f59df47A7f0068ff669,0x20e442476D13D37f34D41f62E9213A49DC543f05,0x0d1D163C1d9f02538124Dff11e7803CE8e9bd21C,0x48b06CcE5D407D7e650DEf3c29585F89dAFe05E1,0x2d463831988a210a87E1ba69dbBDD759d98788BD,0x33F34F9f638eC5c37d7eD4C0427185FF337bCcd9,0xa0f1cf987D6A10BcB5383C11419024597DF425b0,0x213bEa4D8CBA9EdAc7396C14Af2505D065fD464F,0xEdA8f9f57473d7324EF84b84462bCc865bF675A8,0xd85378637EeE044aD4Fd43DdaDe466E85855e993,0x4943d1F19f6aa846f6e72cc09f12E6eEA0b38De6,0xe7F2BCa664d1Bc2EC56878C8Afc8cD58E26aD29c,0x2228222Cc12a38F1598EC48C85c3b7a8C6b1c7C7,0x528A95267DfC3e48Fb040E192DF6F3F49D8Fca54,0x4E791949682653231B73876Deb29b9C2348a47AB,0x956E561e8B12A4C322D11137CA42207Fab8536B6,0x931966c0AdFBBd3284Eec7C57B3d6C17bAF1db8c,0x8718020Cd4f42aaB9F317ae713391754229B3502,0xb3F8234C67Ee7CBAaD34845caB22b32318CA28fF,0x232B666df662f77c4149b6Afa5083E8591Dd09f2,0x071c80257A56354a000353ec48Ecf1EF01c049d8,0x09174aa753d1EAeAc9D61CA86BeDeb40303ebb1e,0x9483d410A55F653E89ff79C0Ec33eE8f9Eb09cB2,0xfc6717dF7Bf3Bf66681dda9641C0Cb88B68c5D3c,0x801D092924b4E6eb7b1DEcbE7C2a7b94189350FC,0xC36D3fB53Dc252456C01Abe61eE6950A1e4b8871,0x2dA14fB0FA463916D2E5249b6c37198Fedc76A3a,0xaa1D37790Ac736F89f5Ea821aD8F370e42e9fF6e,0xeDc7D38506cb163f63E7Bad97cB458Cc6F603282,0x63C8AA09861aDFE54BC1c5A2e59B46d9E23Ebd4d,0xb922419B1C0F6e63442370119d6D25482aD5CF25,0x7510aCf84125508e9A4543537f4eFcf9c4C2D488,0xd64B28A5f432F804c80bA3bC9f79B4Eafa5636D6,0xe3ce52f25EC6B2606ac5D8C52D609d26Db2283DC,0x7d7E14477CdbD7431Acb6B62563Eb87b94E6f588,0xce341eDD9682751300e64E097dA1D485Bfab9977,0xce8EEF6219d2db12cc3463B7ad8B5AF62b7b8D6a,0x1656911C9c167C1430e0f9d312EfAc22913B971d,0xB2d694e2F4C279aAA29d8F761D307810b0609ECD,0x4C62cAb3366b5F3b4a21BA51b269F8A6A0F3447A,0x79EFcFAacDBcC61E663879f4AD198b2907A45657,0xE1804AA5f71968d159B48F23832763b7f5AC38cf,0xAC61a0fb7e22fBBC82B02b5dF1D22da70C332BC0,0xD7873fDCCf95d7b81a34Deee6123eDb2BdC3d043,0xF6040954C5199517482cCBCC22893064C760cd4d,0x20E003d0dd366AFf5DcE62C54cbCE85a169BfF1f,0xC6e92C6a87624F40e2eea5d8EFb84aCc1544e61D,0xBdac8DF009B7cf44555A901eE46Ea51FE57a1EcF,0xC68b4dDcB2F54400D934b9B43A056F1699f7b2ae,0x83aa2afEDd12A5Ea9Cb3CE4D236F208F91597B3c,0x8e99dDA70Fcd15E1a0dd3266B38c699334Cb0B4A,0xdb5bf2Ae5702b25d61B40161997e06195017aA35,0xa2a907B937E574A863E309f0a0309ffb1a487C75,0x54091bA29B4FAF32809DcD4B5c16d7412d02DceC,0x19bc600C1d7da1e33352f2EBb8141940959d5680,0x6F67A1Bd2633DB5893A02e61D01191070C4514F6,0x66a824fCA549Aed5cE8383017Fc1B944748F9376,0x03FDBDe3dcDf388fCe8A6723cfBcc05aD9b59554,0xcE22cC8ea071ea9E91b6DfD7c3B16539BBb10932,0xf52a6b2F15869470c22291d9526491d2069BcE86,0x497bB653398F2c9d9140adcC9914CD5abB22e3E4,0x3ef5F6Be40100877179D17dFF0FF42fE8e778260,0xeB2E1e545Ad241b0fBBf5C451E2594718046686F,0xF04E6aE61ca0715871d512E244664C97373C3764,0xa4aDD934E2189aDd770f440dEc4Ac535A6310852,0xa8293632EA205bB412aF45E079F664a37a97A705,0xF274b0dCBE4486fE892F7C80D814A1c75E635102,0x7c05813f965Ff2863ffD1340b104797E46856722,0x65223fD1C30BE342C1C01Dce3f226200aB80d041,0x7AdD7501bbe1a7e0CA4f6e5aBd771BC528A634bF,0x7452E0B0297f794f77294CfC896E66f091c8009E,0x61aa678C19DBDf9e7ada172cb8fF5568B95873D3,0x8E70CD5d17707A2980D84de7EF0bd226f89eA1D8,0x6C47c243DD077E979F5bc994BD20a936650CB353,0x08f0352976A1af92b12bDa7B8F4fCE139182C59F,0xF356899f541f67217E3B1C7b8681fF7AcbB9b909,0xb900A2b3B2A5f075DAa19f124758273E922c8b53,0xf1Efd0C80b714500AB4486561ffB7208c38e9576,0x2dD57564249d77e1672984518E1B5A6D574623A4,0x7539c186a65625787bB8873Ed1d6C42A6Ea4d4ac,0x3467c440c2f3ef0f34Ee40e7a420815644723a04,0x3ebc1e77297AD0f9098833272a44C6B1448540C3,0x5d611C9E23C7c8f1A25bFd0db6aDe6403B437386,0x1Fc8ad7672a5bb14f169a5A872CEF134f6Dee78b,0x464A285EB3F7e1f89661c106Cd123F5EA3d1c6D1,0x4672913B4d0cEca7359EA628414eC1bFf4dC7F85,0x10812B549FB8e0884807501F98268cEbB88eDDA4,0xC6f8Fbd63CE6cAC8cCC8859eECFd4864575d0582,0xF98fca1c8eA67CF44572Fb169Dc0A7a75Ab08215,0xf420D49935B29F8f0594f14a04340a336A4C6BF5,0xA72457F144c4D4d7c1D736548177b933323523dC]" "[42353797,5272210,948911,28198663,33457346,31634638,40085553,37170516,29449069,421859,17875742,47081474,26185341,16852803,45698805,8982173,2411704,34709755,23648386,34138700,8101851,9045313,45074247,41006804,30082188,5318793,41044940,1204591,41623026,34096709,21704156,6024885,49774608,29076621,39442924,19744195,10577617,48730276,32168748,40734169,40671811,6762005,26956245,25471945,15588649,34640667,45772791,8489528,14968494,13124550,18545689,29018411,45146609,37028663,25517081,35198161,35701117,30834422,20897742,41897500,13094723,28430492,48551947,40196899,35206834,23977649,39369029,6989691,25410422,46140815,7766559,14319381,3407082,34126430,12747979,1148111,10351714,33465150,11542593,24042898,13970465,24288787,22506334,11246367,18428094,8661189,7841578,6162633,47389476,30801942,46923796,21999944,42314948,26819850,36552542,44132488,28573297,30571776,25229845,33638982,45798556,21278108,7558982,26504378,48554571,41675524,44933639,11839241,19242637,7960263,49300293,49355710,11946251,45971388,36545285,30318301,2851506,15786432,17362672,300724,7213751,43372887,43462593,39373903,22781053,41497656,44555427,10684449,6712686,26387682,2239899,10620873,18048229,7673933,33043026,3181170,4307239,19887557,27081442,3582746,7404028,40981757,8094257,13053410,31065601,2793115,7295011,18317577,37056385,10186290,18854642,23295874,29473188,9816264,46838482,16064433,30868710,30117174,33640639,8254583,30433018,32286078,22304173,43861414,14717078,1660947,31150757,28557617,29660121,21256032,4448152,46139494,21995893,49160852,16395270,11682389,30394661,13749385,3910022,28714620,669578,12490265,32558939,34252525,6432052,45959385,3808021,42799360,33309057,16353787,1463235,6542692,24037420,42251656,21655302,11611847,35300516,34401245,12153466,41283985]" --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY  src/WLD2.sol:WLD
```
