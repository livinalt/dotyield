import { ethers, BrowserProvider, Contract, type Signer } from "ethers";

const VAULT = "0xD8846806e200604428E6c40f6c3ed6B80c3a70DF";

const ABI = [
  "function deposit() payable",
  "function withdraw(uint256)",
  "function depositERC20(address,uint256)",
  "function withdrawERC20(address,uint256)",
  "function executeStrategy(uint256,address,uint256,string)",
  "function getStrategyCount() view returns (uint256)",
  "function strategies(uint256) view returns (address,string,uint256,string)",

  // View functions for multi-token support and user balances
  "function getUserStrategyBalance(address,uint256,address) view returns (uint256)",
  "function getUserAllStrategyBalances(address,address) view returns (uint256[])",

  // Withdraw from strategy
  "function withdrawFromStrategy(uint256,address,uint256)",

  // EVENTS
  "event Deposited(address indexed user,address indexed token,uint256 amount)",
  "event Withdrawn(address indexed user,address indexed token,uint256 amount)",
  "event StrategyExecuted(address indexed user,address indexed strategy,address token,uint256 amount,string aiReason)",
] as const;


let provider: BrowserProvider | null = null;
let signer: Signer | null = null;
let contract: Contract | null = null;

export async function initEthers() {
  if (!window.ethereum) {
    throw new Error("No Ethereum provider found");
  }

  if (provider && signer && contract) return;

  provider = new BrowserProvider(window.ethereum);
  await provider.send("eth_requestAccounts", []);

  signer = await provider.getSigner();
  contract = new Contract(VAULT, ABI, signer);
}


interface Strategy {
  address: string;
  name: string;
  risk: number;
  riskScore?: number;
  description: string;
}


export async function depositETH(amount: string) {
  await initEthers();
  if (!contract) throw new Error("Contract not initialized");

  const tx = await contract.deposit({
    value: ethers.parseEther(amount),
  });

  return tx;
}

export async function executeStrategy(
  index: number,
  token: string,
  amount: string,
  reason: string
) {
  await initEthers();
  if (!contract) throw new Error("Contract not initialized");

  const tx = await contract.executeStrategy(
    index,
    token,
    ethers.parseEther(amount),
    reason
  );

  return tx;
}

export async function getStrategies(): Promise<Strategy[]> {
  await initEthers();
  if (!contract) throw new Error("Contract not initialized");

  const count: bigint = await contract.getStrategyCount();
  const strategies: Strategy[] = [];

  for (let i = 0; i < Number(count); i++) {
    const s = await contract.strategies(i);

    strategies.push({
      address: s[0],
      name: s[1],
      risk: Number(s[2]),
      riskScore: Number(s[2]),
      description: s[3],
    });
  }

  return strategies;
}


export async function getAccount(): Promise<string> {
  await initEthers();
  if (!signer) throw new Error("No signer");

  return signer.getAddress();
}

export async function getUserStrategyBalance(
  user: string,
  index: number,
  token: string
) {
  await initEthers();
  if (!contract) throw new Error("Contract not initialized");

  return await contract.getUserStrategyBalance(user, index, token);
}

export async function getUserAllStrategyBalances(
  user: string,
  token: string
) {
  await initEthers();
  if (!contract) throw new Error("Contract not initialized");

  return await contract.getUserAllStrategyBalances(user, token);
}

// Withdraw from strategy function - allows user to pull funds back from a strategy without exiting the vault entirely
export async function withdrawFromStrategy(
  index: number,
  token: string,
  amount: string
) {
  await initEthers();
  if (!contract) throw new Error("Contract not initialized");

  const tx = await contract.withdrawFromStrategy(
    index,
    token,
    ethers.parseEther(amount)
  );

  return tx;
}

// Activity fetch function to get past StrategyExecuted events for a user
export async function getActivity(user: string) {
  await initEthers();
  if (!contract) throw new Error("Contract not initialized");

  const filter = contract.filters.StrategyExecuted(user);
  const logs = await contract.queryFilter(filter, -5000);

  return logs.map((log: any) => ({
    strategy: log.args[1],
    token: log.args[2],
    amount: log.args[3],
    reason: log.args[4],
    txHash: log.transactionHash,
  }));
}