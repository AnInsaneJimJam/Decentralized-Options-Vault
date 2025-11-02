//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import { MockERC20 } from "../contracts/MockERC20.sol";
import { MockStrategy } from "../contracts/MockStrategy.sol";
import { CoveredCallVault } from "../contracts/CoveredCallVault.sol";

/**
 * @notice Deploy script for Decentralized Option Vault (DOV) contracts
 * @dev This script deploys MockERC20, MockStrategy, and CoveredCallVault
 */
contract DeployDOV is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner {

        // Deploy MockERC20 (mETH) with initial supply
        MockERC20 mETH = new MockERC20(
            "Mock ETH",
            "mETH", 
            18,
            1000000, // 1M initial supply
            deployer
        );
        console.logString(string.concat("MockERC20 (mETH) deployed at: ", vm.toString(address(mETH))));

        // Deploy MockStrategy
        MockStrategy strategy = new MockStrategy(
            address(mETH),
            deployer
        );
        console.logString(string.concat("MockStrategy deployed at: ", vm.toString(address(strategy))));

        // Deploy CoveredCallVault
        CoveredCallVault vault = new CoveredCallVault(
            mETH,
            "DOV Covered Call Vault",
            "DOV-CC",
            deployer
        );
        console.logString(string.concat("CoveredCallVault deployed at: ", vm.toString(address(vault))));

        // Set up connections
        strategy.setVault(address(vault));
        vault.setStrategy(address(strategy));

        // Mint some mETH to deployer for testing
        mETH.mint(deployer, 100 ether);
        
        console.logString("=== DOV Deployment Complete ===");
        console.logString(string.concat("mETH Token: ", vm.toString(address(mETH))));
        console.logString(string.concat("Strategy: ", vm.toString(address(strategy))));
        console.logString(string.concat("Vault: ", vm.toString(address(vault))));
        console.logString(string.concat("Deployer: ", vm.toString(deployer)));
        console.logString(string.concat("Deployer mETH Balance: ", vm.toString(mETH.balanceOf(deployer))));
    }

    function test() public {}
}
