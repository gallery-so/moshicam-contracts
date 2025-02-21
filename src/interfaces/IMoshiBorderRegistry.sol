// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiBorderConfig} from "../entities/MoshiBorderConfig.sol";

interface IMoshiBorderRegistry {
    // Emitted when a border is updated
    event BorderUpdated(uint256 indexed id);

    // Raised when the border does not exist
    error ErrUnknownBorder(uint256 id);

    /// Raised when the border creator is invalid
    error InvalidBorderCreator();

    /// @notice Gets the border configuration for the given border
    /// @dev Returns `ErrBorderUnknown` if border is not registered
    /// @param id The id of the border to retrieve
    function getBorder(uint256 id) external view returns (MoshiBorderConfig memory);

    /// @notice Return if a given border is registered
    /// @param id The border id to check
    function exists(uint256 id) external view returns (bool);

    /// @notice Add a new border to the registry
    /// @dev Returns the id of the added border
    /// @param config The config to add
    function addBorder(MoshiBorderConfig calldata config) external returns (uint256);

    /// @notice Add many borders to the registry
    /// @dev Returns the ids of the added borders
    /// @param configs The configs to add
    function addBorders(MoshiBorderConfig[] calldata configs) external returns (uint256[] memory);

    /// @notice Update an existing border's configuration
    /// @param id The border id to update
    /// @param config The new configuration
    function updateBorder(uint256 id, MoshiBorderConfig calldata config) external;

    /// @notice Return the owner
    function owner() external view returns (address);

    /// @notice Return the next border id
    function nextBorderId() external view returns (uint256);
}
