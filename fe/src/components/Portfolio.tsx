import { useEffect, useState } from "react";

export default function Portfolio() {
  const [balance, setBalance] = useState(0);

  useEffect(() => {
    // mock for now (replace with contract later)
    setBalance(1.42);
  }, []);

  return (
    <div className="bg-gray-900 p-6 rounded-xl mb-10">
      <h2 className="text-lg font-bold mb-2">Your Portfolio</h2>

      <p className="text-3xl font-bold">{balance} ETH</p>
      <p className="text-gray-400 text-sm">
        Managed by AI strategies
      </p>
    </div>
  );
}