"use client";

import { motion } from "framer-motion";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import Tilt from "react-parallax-tilt";

function FeatureCard({ title, text }: { title: string; text: string }) {
  return (
    <motion.div
      whileHover={{ scale: 1.05 }}
      className="bg-gray-800/60 p-6 rounded-2xl shadow-lg border border-gray-700 hover:border-gray-500 transition-all backdrop-blur-sm"
    >
      <h3 className="text-xl font-semibold mb-2">{title}</h3>
      <p className="text-gray-400">{text}</p>
    </motion.div>
  );
}

export default function Home() {
  return (
    <main className="relative flex flex-col min-h-screen text-white overflow-hidden">
      <div className="absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-main-gradient" />
        <div className="absolute inset-0 bg-aurora animate-gradient-slow" />
        <div className="absolute inset-0 bg-conic-light animate-spin-slower" />
        <div className="absolute inset-0 bg-stars" />
      </div>

      <div className="flex flex-col items-center justify-center grow px-6">
        <section className="text-center space-y-6 max-w-2xl">
          <motion.h1
            className="text-5xl font-bold tracking-tight"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            Kairos — AI-Driven Onchain Automations
          </motion.h1>

          <motion.p
            className="text-gray-300 text-lg"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2, duration: 0.5 }}
          >
            Automate your DeFi workflows with natural language.
            <br /> Think “Zapier for Web3”.
          </motion.p>

          <motion.div
            className="flex justify-center pt-6"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.5 }}
          >
            <ConnectButton />
          </motion.div>
        </section>

        <section className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-24 max-w-5xl">
          <Tilt tiltMaxAngleX={5} tiltMaxAngleY={5}>
            <FeatureCard
              title="Automate DeFi Actions"
              text="Set recurring swaps, yield harvesting, or bridging with no code."
            />
          </Tilt>
          <Tilt tiltMaxAngleX={5} tiltMaxAngleY={5}>
            <FeatureCard
              title="AI-Powered"
              text="Describe your goal in plain English — Kairos builds the workflow for you."
            />
          </Tilt>
          <Tilt tiltMaxAngleX={5} tiltMaxAngleY={5}>
            <FeatureCard
              title="Onchain Execution"
              text="Everything runs transparently onchain for full security and trust."
            />
          </Tilt>
        </section>
      </div>

      <footer className="text-gray-500 text-sm flex flex-col md:flex-row gap-2 md:gap-4 items-center justify-center pb-8">
        <p>© {new Date().getFullYear()} Kairos — Built for Autonomous DeFi</p>
        <div className="flex gap-4">
          <a
            href="https://github.com/WhatFate"
            target="_blank"
            className="hover:text-white transition"
          >
            GitHub
          </a>
          <a
            href="https://x.com/WhatFatee"
            target="_blank"
            className="hover:text-white transition"
          >
            Twitter
          </a>
          <a href="#" className="hover:text-white transition">
            Docs
          </a>
        </div>
      </footer>
    </main>
  );
}
