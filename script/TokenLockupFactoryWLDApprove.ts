import { Interface, ethers } from "ethers";
import { LedgerSigner } from "@ethers-ext/signer-ledger";
// import HIDTransport from "@ledgerhq/hw-transport-mocker";
import HIDTransport from "@ledgerhq/hw-transport-node-hid";
import dotenv from "dotenv";
import Safe, { EthersAdapter } from "@safe-global/protocol-kit";
import SafeApiKit from "@safe-global/api-kit";
import {
  MetaTransactionData,
  OperationType,
} from "@safe-global/safe-core-sdk-types";
import { ArtifactIERC20 } from "./abi/abi";

dotenv.config();

main();

async function main() {
  const apiKit = new SafeApiKit({
    chainId: 10n,
  });

  const RPC_URL = process.env.RPC_URL || "http://localhost:8545";
  const provider = new ethers.JsonRpcProvider(RPC_URL);

  const signer = new LedgerSigner(HIDTransport, provider);

  const ethAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: signer,
  });

  const safeAddress = process.env.SAFE_ADDRESS!;

  const ierc20Abi = ArtifactIERC20.abi;

  const ierc20Interface = new Interface(ierc20Abi);

  const ierc20ApproveData = ierc20Interface.encodeFunctionData("approve", [
    process.env.FACTORY_ADDRESS!,
    process.env.APPROVAL_AMOUNT!,
  ]);

  // https://optimistic.etherscan.io/address/0xdc6ff44d5d932cbd77b52e5612ba0529dc6226f1
  const wldTokenAddress = "0xdc6ff44d5d932cbd77b52e5612ba0529dc6226f1";

  const safeTransactionData: MetaTransactionData = {
    to: wldTokenAddress,
    data: ierc20ApproveData,
    value: "0",
    operation: OperationType.Call,
  };

  const safe = await Safe.create({
    ethAdapter,
    safeAddress,
  });

  const safeTransaction = await safe.createTransaction({
    transactions: [safeTransactionData],
  });

  const safeTxHash = await safe.getTransactionHash(safeTransaction);

  console.log("Safe transaction hash:", safeTxHash);

  const senderSignature = await safe.signHash(safeTxHash);

  await apiKit.proposeTransaction({
    safeAddress,
    safeTransactionData: safeTransaction.data,
    safeTxHash,
    senderAddress: await safe.getAddress(),
    senderSignature: senderSignature.data,
  });

  console.log("Transaction proposed, check the Safe UI to confirm it.");
}
