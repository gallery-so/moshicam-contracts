// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiContractConfig} from "../entities/MoshiContractConfig.sol";
import {MoshiPicConfig} from "../entities/MoshiPicConfig.sol";

interface IMoshiMinter {
    // Emitted when the admin minter changes
    event AdminMinterChanged(address indexed newAdminMinter);
    // Emitted when a new pic contract is created
    event NewPicContract(address indexed owner, address indexed newContract);
    // Emitted when the pic1155 implementation is set
    event Pic1155ImplSet(address indexed newImpl);

    // Raised when the sender is not the configured contract owner
    error SenderNotNewContractOwner();
    // Raised when sender is not the admin minter
    error NotAdminMinter(address sender);
    // Raised when the pic1155 implementation is not set
    error PicImplementationNotSet();

    /// @notice Mint tokens to `to`
    /// @param to The address to transfer token to
    /// @param quantity The quantity to mint
    /// @param picConfig The pic configuration
    /// @param contractConfig The contract configuration
    function mintNewPic(
        address to,
        uint256 quantity,
        MoshiPicConfig calldata picConfig,
        MoshiContractConfig calldata contractConfig
    ) external payable returns (address, uint256);

    /// @notice Mint a new token to `to`
    /// @param to The address to mint to
    /// @param quantity The quantity to mint
    /// @param picConfig The pic configuration
    /// @param contractConfig The contract configuration
    function mintNewPicAdmin(
        address to,
        uint256 quantity,
        MoshiPicConfig calldata picConfig,
        MoshiContractConfig calldata contractConfig
    ) external returns (address, uint256);

    /// @notice Mint an existing token to `to`
    /// @param pic1155 The address of the MoshiPic1155 contract
    /// @param to The address to mint to
    /// @param id The id of the token to mint
    /// @param quantity The amount to mint
    function collectPic(address pic1155, address to, uint256 id, uint256 quantity) external payable;

    /// @notice Return the pic contract for `account`
    /// @param account The address
    function getPicContract(address account) external view returns (address);

    /// @notice Set the admin minter
    /// @param newMinter The new admin minter
    function setAdminMinter(address newMinter) external;

    /// @notice Return the admin minter
    function adminMinter() external view returns (address);

    /// @notice Set the pic1155 implementation
    /// @param pic1155Impl The new pic1155 implementation
    function setPicImplementation(address pic1155Impl) external;

    /// @notice Return the pic1155 implementation
    function picImplementation() external view returns (address);

    /// @notice Return the owner
    function owner() external view returns (address);
}
