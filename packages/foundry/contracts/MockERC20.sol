//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Mock ERC20 token (mETH) for testing the Decentralized Option Vault
 * @author DOV Team
 */
contract MockERC20 is ERC20, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) Ownable(owner) {
        _decimals = decimals_;
        _mint(owner, initialSupply * 10**decimals_);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * Mint tokens to any address (for testing purposes)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * Mint tokens to caller (for easy testing)
     */
    function mintToSelf(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
