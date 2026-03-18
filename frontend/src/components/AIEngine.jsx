import axios from "axios";
import { executeStrategy } from "../utils/contracts";
import { useState } from "react";

export default function AIEngine() {
  const [loading, setLoading] = useState(false);

  async function runAI() {
    setLoading(true);

    const res = await axios.post("http://localhost:3001/ai-strategy", {
      balance: 1,
    });

    const { strategy, amount, reason } = res.data;

    await executeStrategy(
      strategy,
      "0x0000000000000000000000000000000000000000",
      amount,
      reason
    );

    setLoading(false);
  }

  return (
    <button
      onClick={runAI}
      className="bg-purple-600 px-6 py-3 rounded-xl"
    >
      {loading ? "AI Running..." : "Run AI Strategy"}
    </button>
  );
}