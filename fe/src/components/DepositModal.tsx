import { useState } from "react";
import { depositETH } from "../utils/contracts";

export default function DepositModal({ open, onClose, strategy }) {
  const [amount, setAmount] = useState("");

  if (!open) return null;

  async function handleDeposit() {
    await depositETH(amount);
    onClose();
  }

  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center">
      <div className="bg-gray-900 p-6 rounded-xl w-96">

        <h2 className="text-lg font-bold mb-4">
          Deposit into {strategy?.name}
        </h2>

        <input
          type="text"
          placeholder="Amount (ETH)"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="w-full p-2 rounded bg-black border border-gray-700 mb-4"
        />

        <div className="flex justify-between">
          <button
            onClick={onClose}
            className="text-sm text-gray-400"
          >
            Cancel
          </button>

          <button
            onClick={handleDeposit}
            className="px-4 py-2 text-sm bg-white text-black rounded-lg"
          >
            Deposit
          </button>
        </div>
      </div>
    </div>
  );
}