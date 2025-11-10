import { ethers } from "ethers";
import { writeContract } from "wagmi/actions";
import { sepolia } from "viem/chains";
import { config } from "../providers/Web3Provider";

const abi = [
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "uint256", name: "triggerPrice", type: "uint256" },
    ],
    name: "addActionEth",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "cancelAction",
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
    functionName: "addActionEth",
    args: [target, triggerPrice],
    value: ethers.parseEther(String(amount)),
    address: "0xC8443ecdD36B677e8A15483F8719804F9b60b6E8",
    chainId: sepolia.id,
  });
}

export async function cancelAutomation() {
  await writeContract(config, {
    abi: abi,
    functionName: "cancelAction",
    address: "0xC8443ecdD36B677e8A15483F8719804F9b60b6E8",
    chainId: sepolia.id,
  });
}
