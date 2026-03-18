import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

import "@rainbow-me/rainbowkit/styles.css";
import {
  getDefaultConfig,
  RainbowKitProvider,
} from "@rainbow-me/rainbowkit";

import { WagmiProvider } from "wagmi";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";

const config = getDefaultConfig({
  appName: "DotYield",
  projectId: "demo",
  chains: [
    {
      id: 1287,
      name: "Moonbase Alpha",
      rpcUrls: {
        default: {
          http: ["https://rpc.api.moonbase.moonbeam.network"],
        },
      },
      nativeCurrency: { name: "DEV", symbol: "DEV", decimals: 18 },
    },
  ],
});

const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById("root")).render(
  <WagmiProvider config={config}>
    <QueryClientProvider client={queryClient}>
      <RainbowKitProvider>
        <App />
      </RainbowKitProvider>
    </QueryClientProvider>
  </WagmiProvider>
);