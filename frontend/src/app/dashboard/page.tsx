"use client";

import { useState, useRef } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { askAIBackend } from "@/src/lib/ai/askAIBackend";
import { useAccount } from "wagmi";
import { FiSend } from "react-icons/fi";
import { RiCloseCircleLine } from "react-icons/ri";
import { createAutomation, cancelAutomation } from "@/src/lib/automation";

interface Message {
  role: "user" | "assistant" | "error";
  content: string;
}

export default function Dashboard() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [canceling, setCanceling] = useState(false);
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
      if (response.status === "message") {
        setMessages((prev) => [
          ...prev,
          { role: "assistant", content: response.response },
        ]);
      } else if (response.status === "automation_ready") {
        setMessages((prev) => [
          ...prev,
          { role: "assistant", content: response.prompt },
        ]);
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

  const handleCancel = async () => {
    try {
      setCanceling(true);
      await cancelAutomation();
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: "Your scheduled action has been cancelled.",
        },
      ]);
    } catch (error) {
      console.error("Cancel error:", error);
      setMessages((prev) => [
        ...prev,
        { role: "error", content: "Failed to cancel your action." },
      ]);
    } finally {
      setCanceling(false);
    }
  };

  return (
    <main className="relative flex min-h-screen text-white">
      <aside className="w-64 bg-gray-900/90 backdrop-blur-md p-6 flex flex-col gap-6 shadow-2xl border-r border-gray-700">
        <h2 className="text-xl font-bold mb-2">Your Automation</h2>
        <p className="text-gray-300 text-sm">
          Manage your scheduled actions. For now, only cancelling is available.
        </p>
        <button
          onClick={handleCancel}
          disabled={canceling}
          className={`flex items-center justify-center px-4 py-3 rounded-lg font-semibold text-white transition-all gap-2 ${
            canceling
              ? "bg-red-400 cursor-not-allowed"
              : "bg-red-600 hover:bg-red-700 cursor-pointer"
          }`}
        >
          <RiCloseCircleLine size={20} />
          {canceling ? "Canceling..." : "Cancel Your Scheduled Action"}
        </button>
      </aside>

      <div className="flex-1 flex flex-col h-screen">
        <div className="flex justify-between items-center px-6 py-4 border-b border-gray-700 bg-gray-900/80">
          <h1 className="text-2xl font-bold tracking-wide">Kairos AI Chat</h1>
          <ConnectButton showBalance={false} chainStatus="none" />
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-4 scrollbar-thin scrollbar-thumb-gray-600 scrollbar-track-gray-800 bg-gray-900/80">
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

        <div className="flex px-6 py-4 border-t border-gray-700 gap-3 bg-gray-900/80">
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && sendMessage()}
            placeholder="Type your command..."
            className="flex-1 bg-gray-800/80 text-white placeholder-gray-400 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
            disabled={loading || canceling}
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
