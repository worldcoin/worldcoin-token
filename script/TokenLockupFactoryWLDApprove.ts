import axios, { AxiosResponse } from "axios";
import table from "console-table-printer";
import query from "cli-interact";
import { Interface, ethers } from "ethers";
import { LedgerSigner } from "@ethers-ext/signer-ledger";
import HIDTransport from "@ledgerhq/hw-transport-node-hid";
import dotenv from "dotenv";
import Safe, { EthersAdapter } from "@safe-global/protocol-kit";
import SafeApiKit from "@safe-global/api-kit";
import {
  MetaTransactionData,
  OperationType,
} from "@safe-global/safe-core-sdk-types";
import TokenLockupFactory from "../out/TokenLockupFactory.sol/TokenLockupFactory.json";

/// Constants
const AIRTABLE_API_KEY = process.env.AIRTABLE_API_KEY!;
const AIRTABLE_BASE_ID = process.env.AIRTABLE_BASE_ID || 'appkFOEdAZ6NruSV8';
const AIRTABLE_TABLE_NAME = process.env.AIRTABLE_TABLE_NAME || 'Batch_001';
const SAFE_ADDRESS = process.env.SAFE_ADDRESS || "0xd4b9093c2EA7841C19715e16FC1135B11c6eC1a0";
const RPC_URL = process.env.RPC_URL || "https://mainnet.optimism.io";
const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "0xdc6ff44d5d932cbd77b52e5612ba0529dc6226f1";
const FACTORY_ADDRESS = process.env.FACTORY_ADDRESS || "0x31075DD5B0CAFF37690B2f700dB60Ad0A317a57a";
const DERIVATION_PATH = process.env.DERIVATION_PATH || "44'/60'/1'/0/0";

const AIRTABLE_ENDPOINT = `https://api.airtable.com/v0/${AIRTABLE_BASE_ID}/${AIRTABLE_TABLE_NAME}?view=Grid%20view`;
const HEADERS = {
  Authorization: `Bearer ${AIRTABLE_API_KEY}`,
  'Content-Type': 'application/json',
};

interface TransferDetails {
  beneficiary: string;
  amount: string;
}

interface Fields {
  AmountWLD: string;
  Name: string;
  WalletAddress: string;
}

interface AirtableRecord {
  id: string;
  createdTime: string;
  fields: Fields;
}

interface AirtableResponse {
  records: AirtableRecord[];
}

dotenv.config();

await main();

async function fetchTransferData() {
  const response: AxiosResponse<AirtableResponse> = await axios.get(AIRTABLE_ENDPOINT, { headers: HEADERS });
  const records = response.data.records;

  const transfers: TransferDetails[] = records.map((record) => {
    return {
      beneficiary: record.fields.WalletAddress,
      amount: record.fields.AmountWLD,
    };
  });

  return transfers;
}

async function main() {
  const apiKit = new SafeApiKit({
    chainId: 10n,
  });

  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new LedgerSigner(HIDTransport, provider, DERIVATION_PATH);

  const ethAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: signer,
  });

  const data = await fetchTransferData();

  table.printTable(data);

  const answer = query.getYesNo(`Do you want to proceed with the above mentioned transfers for ** ${AIRTABLE_TABLE_NAME} **?`);

  if (!answer) {
    console.log("Ok terminating.");
    return;
  }

  console.log("Proceeding with the transfers...");

  const tokenFactoryInterface = new Interface(TokenLockupFactory.abi);
  const calldata = tokenFactoryInterface.encodeFunctionData("transfer", [
    TOKEN_ADDRESS,
    await fetchTransferData(),
  ]);

  const safeTransactionData: MetaTransactionData = {
    to: FACTORY_ADDRESS,
    data: calldata,
    value: "0",
    operation: OperationType.Call,
  };

  const safe = await Safe.create({
    ethAdapter,
    safeAddress: SAFE_ADDRESS,
  });

  const safeTransaction = await safe.createTransaction({
    transactions: [safeTransactionData],
  });

  const safeTxHash = await safe.getTransactionHash(safeTransaction);
  console.log("Safe transaction hash:", safeTxHash);
  const senderSignature = await safe.signHash(safeTxHash);

  await apiKit.proposeTransaction({
    safeAddress: SAFE_ADDRESS,
    safeTransactionData: safeTransaction.data,
    safeTxHash,
    senderAddress: await signer.getAddress(),
    senderSignature: senderSignature.data,
  });

  console.log("Transaction proposed, check the Safe UI to confirm it.");
}
