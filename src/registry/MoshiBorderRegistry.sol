// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IMoshiBorderRegistry} from "../interfaces/IMoshiBorderRegistry.sol";
import {MoshiBorderConfig} from "./../entities/MoshiBorderConfig.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @notice Manages border configurations
contract MoshiBorderRegistry is Ownable2StepUpgradeable, UUPSUpgradeable, IMoshiBorderRegistry {
    // Reserve borderId 0 as the default
    uint256 private _nextBorderId;
    // Mapping of border id to config
    mapping(uint256 => MoshiBorderConfig) private _borders;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Restrict upgrade access to owner
    function _authorizeUpgrade(address) internal view override onlyOwner {}

    /// @inheritdoc IMoshiBorderRegistry
    function owner() public view override(IMoshiBorderRegistry, OwnableUpgradeable) returns (address) {
        return OwnableUpgradeable.owner();
    }

    /// @notice Initialize proxy
    /// @param defaultBorderConfig The config to use for the default border
    function initialize(MoshiBorderConfig calldata defaultBorderConfig) public initializer {
        __Ownable_init(msg.sender);
        // Set id 0 as the default configuration
        _addBorder(defaultBorderConfig);
    }

    /// @inheritdoc IMoshiBorderRegistry
    function exists(uint256 id) public view returns (bool) {
        return _borders[id].creator != address(0);
    }

    /// @inheritdoc IMoshiBorderRegistry
    function getBorder(uint256 id) public view returns (MoshiBorderConfig memory config) {
        config = _borders[id];
        if (config.creator == address(0)) {
            revert ErrUnknownBorder(id);
        }
    }

    /// @inheritdoc IMoshiBorderRegistry
    function updateBorder(uint256 id, MoshiBorderConfig calldata config) public onlyOwner {
        if (!exists(id)) {
            revert ErrUnknownBorder(id);
        }
        _updateBorder(id, config);
    }

    /// @dev Update the border with the given config
    /// @param id The id of the border to update
    /// @param _config The new config to use
    function _updateBorder(uint256 id, MoshiBorderConfig calldata _config) private onlyOwner {
        if (_config.creator == address(0)) {
            revert InvalidBorderCreator();
        }
        _borders[id] = _config;
        emit BorderUpdated(id);
    }

    /// @inheritdoc IMoshiBorderRegistry
    function addBorder(MoshiBorderConfig calldata config) external onlyOwner returns (uint256 id) {
        return _addBorder(config);
    }

    /// @inheritdoc IMoshiBorderRegistry
    function addBorders(MoshiBorderConfig[] calldata configs) external onlyOwner returns (uint256[] memory ids) {
        ids = new uint256[](configs.length);
        uint256 localNextBorderId = _nextBorderId;
        for (uint256 i = 0; i < configs.length; i++) {
            ids[i] = localNextBorderId;
            _updateBorder(localNextBorderId, configs[i]);
            localNextBorderId++;
        }
        _nextBorderId = localNextBorderId;
    }

    /// @dev Add a border with the given config
    /// @param _config The config to use for the border
    function _addBorder(MoshiBorderConfig calldata _config) private returns (uint256 id) {
        id = _nextBorderId;
        _updateBorder(_nextBorderId, _config);
        _nextBorderId++;
    }

    /// @inheritdoc IMoshiBorderRegistry
    function nextBorderId() external view override returns (uint256) {
        return _nextBorderId;
    }
}
