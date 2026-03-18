import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

// Routing
import { BrowserRouter } from "react-router-dom";

// RainbowKit
import "@rainbow-me/rainbowkit/styles.css";
import { RainbowKitProvider, getDefaultConfig } from "@rainbow-me/rainbowkit";

// Wagmi + viem
import { WagmiProvider } from "wagmi";
import { http } from "viem"; // ← add this for transport

// React Query
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

// Custom chain: Moonbase Alpha
const moonbaseAlpha = {
  id: 1287,
  name: "Moonbase Alpha",
  network: "moonbase-alpha",
  nativeCurrency: {
    decimals: 18,
    name: "DEV",
    symbol: "DEV",
  },
  rpcUrls: {
    default: { http: ["https://rpc.api.moonbase.moonbeam.network"] },
    public: { http: ["https://rpc.api.moonbase.moonbeam.network"] },
  },
  blockExplorers: {
    default: { name: "Moonscan", url: "https://moonbase.moonscan.io" },
  },
  testnet: true,
} as const;

const config = getDefaultConfig({
  appName: "DotYield",
  projectId: "demo", // ← replace with real WalletConnect project ID (get from cloud.walletconnect.com)
  chains: [moonbaseAlpha],
  transports: {
    [moonbaseAlpha.id]: http(),
  },
});

const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <BrowserRouter>
            <App />
          </BrowserRouter>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  </React.StrictMode>
);