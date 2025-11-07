"use client";

import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultConfig, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { sepolia, baseSepolia } from "viem/chains";
import React from "react";

const config = getDefaultConfig({
  appName: "Kairos",
  projectId: "f1dfb8d5bc2cd53aece8415e48088bfc",
  chains: [sepolia, baseSepolia],
  ssr: false,
});

const queryClient = new QueryClient();

export function RainbowProviders({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider modalSize="compact" showRecentTransactions={true}>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
