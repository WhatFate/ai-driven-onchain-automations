import { ethers } from "ethers";
import { readContract, writeContract } from "wagmi/actions";
import { sepolia } from "viem/chains";
import { config } from "../providers/Web3Provider";

const abi = [
  {
    inputs: [
      { internalType: "bytes", name: "userWorkflow", type: "bytes" },
      {
        internalType: "enum WorkflowManager.ActionType",
        name: "actionType",
        type: "uint8",
      },
      { internalType: "uint256", name: "amount", type: "uint256" },
      { internalType: "address", name: "token", type: "address" },
    ],
    name: "addAction",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "_nonce", type: "uint256" }],
    name: "cancelAction",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "amount", type: "uint256" }],
    name: "calculateFee",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "pure",
    type: "function",
  },
];

const contractAddress = "0x6D2E351Ea84BF281237f1b512b0F5ddFA131acc2";

enum ActionType {
  PriceTrigger = 0,
  ReceiveTrigger = 1,
  TimeTrigger = 2,
}

export async function createAutomation(
  tokenAddress: string,
  recipient: string,
  triggerPrice: number,
  amount: number,
  isGreaterThan: boolean
) {
  const parsedAmount: bigint = ethers.parseEther(amount.toString());

  const abiCoder = new ethers.AbiCoder();
  const encodedWorkflow = abiCoder.encode(
    ["address", "uint96", "uint256", "bool"],
    [recipient, triggerPrice, parsedAmount, isGreaterThan]
  );
  console.log(parsedAmount);
  const fee = (await readContract(config, {
    abi,
    address: contractAddress,
    functionName: "calculateFee",
    args: [parsedAmount],
    chainId: 11155111,
  })) as bigint;

  const isETH = tokenAddress.toLowerCase() === ethers.ZeroAddress;

  const value: bigint = isETH ? parsedAmount + fee : fee;

  await writeContract(config, {
    abi,
    address: contractAddress,
    functionName: "addAction",
    args: [
      encodedWorkflow,
      ActionType.PriceTrigger,
      parsedAmount,
      tokenAddress,
    ],
    value,
    chain: sepolia,
  });
}

export async function cancelAutomation() {
  await writeContract(config, {
    abi: abi,
    functionName: "cancelAction",
    address: contractAddress,
    chainId: sepolia.id,
  });
}
