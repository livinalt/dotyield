import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useEffect, useState } from "react";
import {
  getStrategies,
  getUserAllStrategyBalances,
  getAccount,
  executeStrategy,
  getActivity
} from "../utils/contracts";
import DepositModal from "../components/DepositModal";

export default function Dashboard() {
  const [strategies, setStrategies] = useState([]);
  const [selected, setSelected] = useState(null);
  const [activeTab, setActiveTab] = useState("Your Vaults");

  const [holdings, setHoldings] = useState({});
  const [activity, setActivity] = useState([]);
  const [user, setUser] = useState(null);

  // ✅ TOKENS
  const TOKENS = [
    { symbol: "ETH", address: "0x0000000000000000000000000000000000000000", decimals: 18 },
    { symbol: "USDC", address: "0xYourUSDCAddress", decimals: 6 },
    { symbol: "DAI", address: "0xYourDAIAddress", decimals: 18 },
  ];

  // ✅ MOCK PRICES
  const PRICES = {
    ETH: 3500,
    USDC: 1,
    DAI: 1,
  };

  function calculateTotal(holdings) {
    let total = 0;

    Object.values(holdings).forEach((strategy: any) => {
      strategy.forEach((asset: any) => {
        total += asset.amount * (PRICES[asset.symbol] || 0);
      });
    });

    return total;
  }

  async function loadData() {
    const data = await getStrategies();
    setStrategies(data);

    const account = await getAccount();
    setUser(account);

    let allHoldings = {};

    for (let token of TOKENS) {
      const balances = await getUserAllStrategyBalances(account, token.address);

      balances.forEach((val, i) => {
        if (!allHoldings[i]) allHoldings[i] = [];

        allHoldings[i].push({
          symbol: token.symbol,
          amount: Number(val) / 10 ** token.decimals,
        });
      });
    }

    setHoldings(allHoldings);

    const act = await getActivity(account);
    setActivity(act);
  }

  useEffect(() => {
    loadData();
  }, []);

  // 🤖 AUTO ALLOCATE
  async function autoAllocate() {
    if (!user || strategies.length === 0) return;

    const best = strategies.reduce((prev, curr, i) => {
      return curr.riskScore < prev.riskScore
        ? { ...curr, index: i }
        : prev;
    }, { ...strategies[0], index: 0 });

    await executeStrategy(
      best.index,
      "0x0000000000000000000000000000000000000000",
      "0.01",
      "AI auto allocation"
    );

    await loadData();
  }

  const totalValue = calculateTotal(holdings);

  return (
    <div className="min-h-screen bg-[#0a0a0a] text-white font-sans selection:bg-blue-500/30">
      
      {/* ─── NAVIGATION BAR ─── */}
      <nav className="flex items-center justify-between px-8 border-b border-gray-900 bg-black/50 backdrop-blur-md sticky top-0 z-50">
        <div className="flex items-center gap-8">
          <h1 className="text-sm font-bold">DotYield</h1>
        </div>
        <div className="flex items-center gap-4">
          <ConnectButton chainStatus="icon" showBalance={false} />
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-8 py-8">
        
        {/* ─── ACCOUNT OVERVIEW ─── */}
        <div className="grid grid-cols-1 md:grid-cols-4 border border-gray-800 rounded-t-xl bg-[#111] overflow-hidden">
          <div className="p-6 border-r border-gray-800">
            <p className="text-[10px] uppercase tracking-wider text-gray-500 font-bold mb-1">Total Balance</p>
            <p className="text-3xl font-bold">
              ${totalValue.toFixed(2)}
            </p>
          </div>
          <div className="p-6 border-r border-gray-800">
            <p className="text-[10px] uppercase tracking-wider text-gray-500 font-bold mb-1">Est. Annual Return</p>
            <p className="text-3xl font-bold text-gray-600">—</p>
          </div>
          <div className="p-6 border-r border-gray-800">
            <p className="text-[10px] uppercase tracking-wider text-gray-500 font-bold mb-1">Current APY</p>
            <p className="text-3xl font-bold text-gray-600">—</p>
          </div>
          <div className="p-6">
            <p className="text-[10px] uppercase tracking-wider text-gray-500 font-bold mb-1">30-Day APY</p>
            <p className="text-3xl font-bold text-gray-600">—</p>
          </div>
        </div>

        {/* 🤖 AI BUTTON */}
        <div className="my-6">
          <button
            onClick={autoAllocate}
            className="bg-blue-600 px-4 py-2 rounded-lg font-bold hover:bg-blue-500 transition"
          >
            🤖 Auto Allocate
          </button>
        </div>

        {/* ─── TAB SWITCHER ─── */}
        <div className="flex bg-[#111] border-x border-b border-gray-800 rounded-b-xl mb-12">
          {["Your Vaults", "Activity", "Claim Rewards"].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-4 text-sm font-bold transition-all ${
                activeTab === tab 
                ? "bg-[#1a1a1a] text-white" 
                : "text-gray-500 hover:text-gray-300"
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* ─── VAULTS LIST ─── */}
        {activeTab === "Your Vaults" && (
          <section>
            <div className="flex flex-col mb-6">
              <h3 className="text-2xl font-bold">Your Vaults</h3>
              <p className="text-gray-500 text-sm">Track every DotYield position you currently hold.</p>
            </div>

            <div className="grid grid-cols-4 px-6 py-3 text-[10px] uppercase tracking-widest text-gray-500 font-bold border-b border-gray-800">
              <span>Vault Name</span>
              <span className="text-right">Est. APY</span>
              <span className="text-right">Risk Score</span>
              <span className="text-right">Your Holdings</span>
            </div>

            <div className="bg-[#111] border border-gray-800 rounded-xl mt-2 divide-y divide-gray-800/50">
              {strategies.map((s, i) => (
                <div 
                  key={i} 
                  className="grid grid-cols-4 items-center px-6 py-5 hover:bg-[#1a1a1a] transition-colors cursor-pointer group"
                  onClick={() => setSelected(s)}
                >
                  <div className="flex flex-col">
                    <span className="font-bold group-hover:text-blue-400 transition-colors">{s.name}</span>
                    <span className="text-xs text-gray-500 truncate max-w-[200px]">{s.description}</span>
                  </div>

                  <div className="text-right font-mono text-emerald-400">12.4%</div>

                  <div className="text-right">
                    <span className="text-xs px-2 py-1 rounded border border-gray-700">
                      Level {s.riskScore ?? s.risk}
                    </span>
                  </div>

                  <div className="text-right font-bold text-gray-400">
                    {holdings[i]?.map((h, idx) => (
                      <div key={idx}>
                        {h.amount.toFixed(4)} {h.symbol}
                      </div>
                    )) || "0.00"}
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* ─── ACTIVITY TAB ─── */}
        {activeTab === "Activity" && (
          <div className="bg-[#111] border border-gray-800 rounded-xl p-6">
            {activity.length > 0 ? (
              activity.map((a, i) => (
                <div key={i} className="mb-4 border-b border-gray-800 pb-3">
                  <p className="text-sm text-gray-300">{a.reason}</p>
                  <p className="text-xs text-gray-500">
                    {Number(a.amount) / 1e18} tokens
                  </p>
                </div>
              ))
            ) : (
              <p className="text-gray-500">No activity yet</p>
            )}
          </div>
        )}

      </main>

      <DepositModal
        open={!!selected}
        strategy={selected}
        onClose={() => setSelected(null)}
        onSuccess={loadData}
      />
    </div>
  );
}