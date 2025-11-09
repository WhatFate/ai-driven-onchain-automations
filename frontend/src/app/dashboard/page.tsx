"use client";

import { useState, useRef } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { askAIBackend } from "@/src/lib/ai/askAIBackend";
import { useAccount } from "wagmi";
import { FiSend } from "react-icons/fi";
import { createAutomation } from "@/src/lib/createAutomation";
import { time } from "console";

interface Message {
  role: "user" | "assistant" | "error";
  content: string;
}

export default function Dashboard() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const { address } = useAccount();

  const sendMessage = async () => {
    if (!input.trim()) return;

    const userMessage: Message = { role: "user", content: input };
    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setLoading(true);

    try {
      const response = await askAIBackend(userMessage.content, address!);
      if (response.status == "message") {
        const aiMessage: Message = {
          role: "assistant",
          content: response.response,
        };
        setMessages((prev) => [...prev, aiMessage]);
      } else if (response.status == "automation_ready") {
        const aiMessage: Message = {
          role: "assistant",
          content: response.prompt,
        };
        setMessages((prev) => [...prev, aiMessage]);
        await createAutomation(
          response.workflow.action_amount,
          response.workflow.action_to,
          response.workflow.trigger_value
        );
      }
    } catch (error) {
      console.error("AI Chat error:", error);
      setMessages((prev) => [
        ...prev,
        { role: "error", content: "Error contacting AI backend." },
      ]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="relative flex flex-col items-center justify-center min-h-screen text-white overflow-hidden">
      <div className="absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-main-gradient" />
        <div className="absolute inset-0 bg-aurora animate-gradient-slow opacity-40" />
        <div className="absolute inset-0 bg-conic-light animate-spin-slower opacity-30" />
        <div className="absolute inset-0 bg-stars opacity-20" />
      </div>

      <div className="w-full max-w-3xl bg-gray-900/80 backdrop-blur-md rounded-3xl shadow-2xl flex flex-col h-[600px] overflow-hidden">
        <div className="flex justify-between items-center px-6 py-4 border-b border-gray-700">
          <h1 className="text-2xl font-bold tracking-wide">Kairos AI Chat</h1>
          <ConnectButton showBalance={false} chainStatus="none" />
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-4 scrollbar-thin scrollbar-thumb-gray-600 scrollbar-track-gray-800">
          {messages.map((msg, idx) => (
            <div
              key={idx}
              className={`p-4 rounded-xl max-w-[75%] whitespace-pre-wrap transition-all ${
                msg.role === "user"
                  ? "bg-blue-600 self-end text-white shadow-md"
                  : msg.role === "assistant"
                  ? "bg-gray-800 self-start text-gray-100 font-mono shadow-inner"
                  : "bg-red-600 self-start text-white font-mono shadow-inner"
              }`}
            >
              {msg.content}
            </div>
          ))}
          <div ref={messagesEndRef} />
        </div>

        <div className="flex px-6 py-4 border-t border-gray-700 gap-3">
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && sendMessage()}
            placeholder="Type your command..."
            className="flex-1 bg-gray-800/80 text-white placeholder-gray-400 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
            disabled={loading}
          />
          <button
            onClick={sendMessage}
            disabled={loading}
            className={`flex items-center justify-center px-6 py-3 rounded-xl font-semibold text-white transition-all gap-2 ${
              loading
                ? "bg-blue-400 cursor-not-allowed"
                : "bg-blue-600 hover:bg-blue-700 cursor-pointer"
            }`}
          >
            <FiSend size={18} />
            {loading ? "Sending..." : "Send"}
          </button>
        </div>
      </div>
    </main>
  );
}
