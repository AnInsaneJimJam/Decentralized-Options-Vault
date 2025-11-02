"use client";

import { useState } from "react";
import type { NextPage } from "next";
import { formatEther, parseEther } from "viem";
import { useAccount } from "wagmi";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

const DOVPage: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [depositAmount, setDepositAmount] = useState("");
  const [withdrawShares, setWithdrawShares] = useState("");

  // Contract reads
  const { data: vaultMetrics } = useScaffoldReadContract({
    contractName: "CoveredCallVault",
    functionName: "getVaultMetrics",
  });

  const { data: userShares } = useScaffoldReadContract({
    contractName: "CoveredCallVault",
    functionName: "balanceOf",
    args: [connectedAddress],
  });

  const { data: mETHBalance } = useScaffoldReadContract({
    contractName: "MockERC20",
    functionName: "balanceOf",
    args: [connectedAddress],
  });

  const { data: canRoll } = useScaffoldReadContract({
    contractName: "CoveredCallVault",
    functionName: "canRollStrategy",
  });

  const { data: timeUntilRoll } = useScaffoldReadContract({
    contractName: "CoveredCallVault",
    functionName: "timeUntilNextRoll",
  });

  // Vault address from deployment
  const VAULT_ADDRESS = "0x8ce361602b935680e8dec218b820ff5056beb7af";

  // Contract writes
  const { writeContractAsync: mintMETH } = useScaffoldWriteContract("MockERC20");
  const { writeContractAsync: approveMETH } = useScaffoldWriteContract("MockERC20");
  const { writeContractAsync: depositToVault } = useScaffoldWriteContract("CoveredCallVault");
  const { writeContractAsync: withdrawFromVault } = useScaffoldWriteContract("CoveredCallVault");
  const { writeContractAsync: rollStrategy } = useScaffoldWriteContract("CoveredCallVault");

  const handleMintMETH = async () => {
    try {
      await mintMETH({
        functionName: "mintToSelf",
        args: [parseEther("1000")],
      });
    } catch (error) {
      console.error("Error minting mETH:", error);
    }
  };

  const handleDeposit = async () => {
    if (!depositAmount || !connectedAddress) return;

    try {
      const amount = parseEther(depositAmount);

      // First approve the vault to spend mETH
      await approveMETH({
        functionName: "approve",
        args: [VAULT_ADDRESS, amount],
      });

      // Then deposit to vault
      await depositToVault({
        functionName: "deposit",
        args: [amount, connectedAddress],
      });

      setDepositAmount("");
    } catch (error) {
      console.error("Error depositing:", error);
    }
  };

  const handleWithdraw = async () => {
    if (!withdrawShares || !connectedAddress) return;

    try {
      const shares = parseEther(withdrawShares);

      await withdrawFromVault({
        functionName: "redeem",
        args: [shares, connectedAddress, connectedAddress],
      });

      setWithdrawShares("");
    } catch (error) {
      console.error("Error withdrawing:", error);
    }
  };

  const handleRollStrategy = async () => {
    try {
      await rollStrategy({
        functionName: "rollStrategy",
      });
    } catch (error) {
      console.error("Error rolling strategy:", error);
    }
  };

  const formatTime = (seconds: bigint | undefined) => {
    if (!seconds) return "0s";
    const num = Number(seconds);
    if (num === 0) return "Ready";

    const hours = Math.floor(num / 3600);
    const minutes = Math.floor((num % 3600) / 60);
    const secs = num % 60;

    if (hours > 0) return `${hours}h ${minutes}m`;
    if (minutes > 0) return `${minutes}m ${secs}s`;
    return `${secs}s`;
  };

  return (
    <div className="flex items-center flex-col grow pt-10">
      <div className="px-5 max-w-4xl w-full">
        <h1 className="text-center">
          <span className="block text-4xl font-bold mb-2">Decentralized Option Vault</span>
          <span className="block text-xl text-gray-600">Covered Call Strategy</span>
        </h1>

        <div className="flex justify-center items-center space-x-2 flex-col mb-8">
          <p className="my-2 font-medium">Connected Address:</p>
          <Address address={connectedAddress} />
        </div>

        {/* Vault Metrics */}
        <div className="bg-base-100 rounded-3xl p-6 mb-8">
          <h2 className="text-2xl font-bold mb-4">Vault Metrics</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <p className="text-sm text-gray-600">TVL</p>
              <p className="text-xl font-bold">{vaultMetrics ? formatEther(vaultMetrics[0]) : "0"} mETH</p>
            </div>
            <div className="text-center">
              <p className="text-sm text-gray-600">Share Price</p>
              <p className="text-xl font-bold">
                {vaultMetrics ? (Number(vaultMetrics[1]) / 1e18).toFixed(4) : "1.0000"}
              </p>
            </div>
            <div className="text-center">
              <p className="text-sm text-gray-600">Total Yield</p>
              <p className="text-xl font-bold">{vaultMetrics ? formatEther(vaultMetrics[2]) : "0"} mETH</p>
            </div>
            <div className="text-center">
              <p className="text-sm text-gray-600">Strategy Active</p>
              <p className="text-xl font-bold">{vaultMetrics?.[3] ? "✅" : "❌"}</p>
            </div>
          </div>
        </div>

        {/* User Portfolio */}
        <div className="bg-base-100 rounded-3xl p-6 mb-8">
          <h2 className="text-2xl font-bold mb-4">Your Portfolio</h2>
          <div className="grid grid-cols-2 gap-4">
            <div className="text-center">
              <p className="text-sm text-gray-600">mETH Balance</p>
              <p className="text-xl font-bold">{mETHBalance ? formatEther(mETHBalance) : "0"} mETH</p>
            </div>
            <div className="text-center">
              <p className="text-sm text-gray-600">Vault Shares</p>
              <p className="text-xl font-bold">{userShares ? formatEther(userShares) : "0"}</p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          {/* Mint mETH */}
          <div className="bg-base-100 rounded-3xl p-6">
            <h3 className="text-xl font-bold mb-4">Get Test Tokens</h3>
            <button className="btn btn-primary w-full" onClick={handleMintMETH}>
              Mint 1000 mETH
            </button>
          </div>

          {/* Deposit */}
          <div className="bg-base-100 rounded-3xl p-6">
            <h3 className="text-xl font-bold mb-4">Deposit to Vault</h3>
            <div className="space-y-4">
              <input
                type="number"
                placeholder="Amount in mETH"
                className="input input-bordered w-full"
                value={depositAmount}
                onChange={e => setDepositAmount(e.target.value)}
              />
              <button
                className="btn btn-success w-full"
                onClick={handleDeposit}
                disabled={!depositAmount || !connectedAddress}
              >
                Deposit
              </button>
            </div>
          </div>

          {/* Withdraw */}
          <div className="bg-base-100 rounded-3xl p-6">
            <h3 className="text-xl font-bold mb-4">Withdraw from Vault</h3>
            <div className="space-y-4">
              <input
                type="number"
                placeholder="Shares to redeem"
                className="input input-bordered w-full"
                value={withdrawShares}
                onChange={e => setWithdrawShares(e.target.value)}
              />
              <button
                className="btn btn-warning w-full"
                onClick={handleWithdraw}
                disabled={!withdrawShares || !connectedAddress}
              >
                Withdraw
              </button>
            </div>
          </div>

          {/* Keeper Action */}
          <div className="bg-base-100 rounded-3xl p-6">
            <h3 className="text-xl font-bold mb-4">Strategy Management</h3>
            <div className="space-y-4">
              <div className="text-center">
                <p className="text-sm text-gray-600">Next Roll Available In:</p>
                <p className="text-lg font-bold">{formatTime(timeUntilRoll)}</p>
              </div>
              <button className="btn btn-accent w-full" onClick={handleRollStrategy} disabled={!canRoll}>
                {canRoll ? "🎯 Roll Strategy (Keeper)" : "⏳ Wait for Next Cycle"}
              </button>
            </div>
          </div>
        </div>

        {/* Info */}
        <div className="bg-base-200 rounded-3xl p-6">
          <h3 className="text-xl font-bold mb-4">How It Works</h3>
          <div className="space-y-2 text-sm">
            <p>
              • <strong>Deposit:</strong> Add mETH to the vault to receive shares
            </p>
            <p>
              • <strong>Strategy:</strong> Vault automatically sells covered call options weekly
            </p>
            <p>
              • <strong>Yield:</strong> Earn premiums from option sales (5% per cycle)
            </p>
            <p>
              • <strong>Keeper:</strong> Anyone can trigger the weekly strategy roll
            </p>
            <p>
              • <strong>Risk:</strong> If options expire ITM, collateral may be exercised
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DOVPage;
