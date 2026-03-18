import { ethers } from "ethers";

const VAULT = "0xD8846806e200604428E6c40f6c3ed6B80c3a70DF";

const ABI = [
  "function deposit() payable",
  "function withdraw(uint256)",
  "function depositERC20(address,uint256)",
  "function withdrawERC20(address,uint256)",
  "function executeStrategy(uint256,address,uint256,string)",
  "function getStrategyCount() view returns (uint256)",
  "function strategies(uint256) view returns (address,string,uint256,string)",
];

let provider, signer, contract;

export async function init() {
  provider = new ethers.BrowserProvider(window.ethereum);
  signer = await provider.getSigner();
  contract = new ethers.Contract(VAULT, ABI, signer);
}

export async function depositETH(amount) {
  await init();
  return contract.deposit({ value: ethers.parseEther(amount) });
}

export async function executeStrategy(index, token, amount, reason) {
  await init();
  return contract.executeStrategy(
    index,
    token,
    ethers.parseEther(amount),
    reason
  );
}

export async function getStrategies() {
  await init();
  const count = await contract.getStrategyCount();
  let arr = [];

  for (let i = 0; i < count; i++) {
    const s = await contract.strategies(i);
    arr.push({
      address: s[0],
      name: s[1],
      risk: Number(s[2]),
      description: s[3],
    });
  }

  return arr;
}