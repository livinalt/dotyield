import { ConnectButton } from "@rainbow-me/rainbowkit";
import AIEngine from "./components/AIEngine";
import { useEffect, useState } from "react";
import { getStrategies } from "./utils/contracts";
import { motion } from "framer-motion";

export default function App() {
  const [strategies, setStrategies] = useState([]);

  useEffect(() => {
    getStrategies().then(setStrategies);
  }, []);

  return (
    <div className="bg-black text-white min-h-screen">
      
      {/* NAV */}
      <header className="flex justify-between items-center p-6 border-b border-gray-800">
        <h1 className="text-xl text-red-900 font-bold">DotYield</h1>
        <ConnectButton />
      </header>

      {/* HERO */}
      <section className="text-center py-20 px-6">
        <motion.h1 
          initial={{ opacity: 0, y: 20 }} 
          animate={{ opacity: 1, y: 0 }}
          className="text-5xl font-bold mb-6"
        >
          AI-Powered Yield Optimization
        </motion.h1>

        <p className="text-gray-400 max-w-xl mx-auto mb-8">
          Automatically allocate your crypto across the best strategies using AI.
          No manual research. No stress. Just optimized yield.
        </p>

        <AIEngine />
      </section>

      {/* PROBLEM */}
      <section className="py-16 px-6 max-w-5xl mx-auto">
        <h2 className="text-3xl font-bold mb-6">The Problem</h2>
        <p className="text-gray-400">
          DeFi is fragmented across chains, protocols, and strategies. Users are forced
          to constantly monitor markets, manage risk, and move funds manually.
        </p>
      </section>

      {/* SOLUTION */}
      <section className="py-16 px-6 bg-gray-900">
        <h2 className="text-3xl font-bold mb-6 text-center">The Solution</h2>

        <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          <div className="p-6 bg-black rounded-xl">
            <h3 className="font-bold mb-2">AI Decisions</h3>
            <p className="text-gray-400 text-sm">
              AI analyzes risk, yield, and market conditions in real time.
            </p>
          </div>

          <div className="p-6 bg-black rounded-xl">
            <h3 className="font-bold mb-2">Auto Execution</h3>
            <p className="text-gray-400 text-sm">
              Smart contracts execute strategies automatically.
            </p>
          </div>

          <div className="p-6 bg-black rounded-xl">
            <h3 className="font-bold mb-2">Cross-Chain Ready</h3>
            <p className="text-gray-400 text-sm">
              Built for Polkadot and multi-chain expansion.
            </p>
          </div>
        </div>
      </section>

      {/* HOW IT WORKS */}
      <section className="py-16 px-6 max-w-5xl mx-auto">
        <h2 className="text-3xl font-bold mb-10 text-center">How It Works</h2>

        <div className="grid md:grid-cols-3 gap-6 text-center">
          <div>
            <h3 className="font-bold">1. Deposit</h3>
            <p className="text-gray-400 text-sm">
              Add ETH or stablecoins into the vault
            </p>
          </div>

          <div>
            <h3 className="font-bold">2. AI Chooses</h3>
            <p className="text-gray-400 text-sm">
              Gemini AI selects optimal strategy
            </p>
          </div>

          <div>
            <h3 className="font-bold">3. Earn Yield</h3>
            <p className="text-gray-400 text-sm">
              Funds are deployed automatically
            </p>
          </div>
        </div>
      </section>

      {/* STRATEGIES */}
      <section className="py-16 px-6 bg-gray-900">
        <h2 className="text-3xl font-bold mb-10 text-center">
          Available Strategies
        </h2>

        <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {strategies.map((s, i) => (
            <div key={i} className="p-6 bg-black rounded-xl">
              <h3 className="font-bold">{s.name}</h3>
              <p className="text-gray-400 text-sm">{s.description}</p>
              <p className="text-yellow-400 mt-2">Risk: {s.risk}</p>
            </div>
          ))}
        </div>
      </section>

      {/* AI CTA */}
      <section className="py-20 text-center">
        <h2 className="text-3xl font-bold mb-6">
          Let AI Manage Your Portfolio
        </h2>

        <AIEngine />
      </section>

      {/* FOOTER */}
      <footer className="text-center text-gray-500 text-sm pb-10">
        Built for Polkadot Hackathon • DotYield
      </footer>
    </div>
  );
}