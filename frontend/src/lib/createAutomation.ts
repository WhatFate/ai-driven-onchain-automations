import { ethers } from "ethers";
import { writeContract } from "wagmi/actions";
import { sepolia } from "viem/chains";
import { config } from "../providers/Web3Provider";

const abi = [
  {
    inputs: [
      { internalType: "uint256", name: "amount", type: "uint256" },
      { internalType: "address", name: "target", type: "address" },
      { internalType: "uint256", name: "triggerPrice", type: "uint256" },
    ],
    name: "addAction",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "user", type: "address" }],
    name: "execute",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export async function createAutomation(
  amount: number,
  target: string,
  triggerPrice: string
) {
  await writeContract(config, {
    abi: abi,
    functionName: "addAction",
    args: [ethers.parseEther(String(amount)), target, triggerPrice],
    address: "0x5B5fb0399F1d2EFA669087D1CD13006FD6063a43",
    chainId: sepolia.id,
  });
}
