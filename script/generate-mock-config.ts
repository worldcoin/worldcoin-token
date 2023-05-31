import fs from "fs";
import crypto from "crypto";
import readline from "readline";

import { ethers } from "ethers";

const CONFIG_FILENAME: string = "script/.deploy-config.json";

type Address = string;

function generateBeneficiaries(addressCount: number): Address[] {
  const initialBeneficiaries: Address[] = [];

  for (let i = 0; i < 200; i++) {
    const id = crypto.randomBytes(32).toString("hex");
    const privateKey = "0x" + id;
    const wallet = new ethers.Wallet(privateKey);

    initialBeneficiaries.push(wallet.address);
  }

  return initialBeneficiaries;
}

function getRandomInt(min: number, max: number): number {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min) + min); // The maximum is exclusive and the minimum is inclusive
}

function generateInitialBalances(
  supplyCap: number,
  beneficiariesCount: number
): number[] {
  const initialBalances: number[] = [];

  for (let i = 0; i < beneficiariesCount; i++) {
    const balance = getRandomInt(1, supplyCap / beneficiariesCount);
    initialBalances.push(balance);
  }

  return initialBalances;
}

function writeToJson(
  initialBeneficiaries: Address[],
  initialBalances: number[]
) {
  const oldData = (() => {
    try {
      return JSON.parse(fs.readFileSync(CONFIG_FILENAME).toString());
    } catch {
      return {};
    }
  })();

  const newData = {
    initialBeneficiaries: initialBeneficiaries,
    initialBalances: initialBalances,
  };

  const data = JSON.stringify({ ...oldData, ...newData });
  fs.writeFileSync(CONFIG_FILENAME, data);
}

async function main() {
  const initialBeneficiaries = generateBeneficiaries(200);
  const initialBalances = generateInitialBalances(
    10e9,
    initialBeneficiaries.length
  );

  console.log(initialBeneficiaries);
  console.log(initialBalances);

  writeToJson(initialBeneficiaries, initialBalances);
}

main().then(() => process.exit(0));
