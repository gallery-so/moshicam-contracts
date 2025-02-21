// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiContractConfig} from "../entities/MoshiContractConfig.sol";
import {MoshiPicConfig} from "../entities/MoshiPicConfig.sol";
import {IMoshiMinter} from "../interfaces/IMoshiMinter.sol";
import {IMoshiPic1155} from "../interfaces/IMoshiPic1155.sol";
import {MoshiPic1155Proxy} from "../pic1155/MoshiPic1155Proxy.sol";

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PermissionCallable} from "smart-wallet-permissions/utils/PermissionCallable.sol";

/// @title Manage onboarding and minting of new MoshiPic1155 contracts
contract MoshiMinterImpl is
    Initializable,
    Ownable2StepUpgradeable,
    UUPSUpgradeable,
    IMoshiMinter,
    PermissionCallable
{
    // The admin minter address
    address private _adminMinter;
    // The pic1155 implementation address
    address public pic1155Impl;
    // Mapping of owner to pic contract
    mapping(address => address) public picContractOf;

    /// @dev Reverts if the sender is not the admin minter
    modifier onlyAdminMinter() {
        if (msg.sender != _adminMinter) {
            revert NotAdminMinter(msg.sender);
        }
        _;
    }

    /// @dev Reverts if the pic1155 implementation is not set
    modifier picImplementationSet() {
        if (pic1155Impl == address(0)) {
            revert PicImplementationNotSet();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize proxy
    /// @param owner_ The owner address
    /// @param initialAdminMinter The admin minter address
    function initialize(address owner_, address initialAdminMinter) public initializer {
        require(owner_ != address(0), "owner cannot be zero address");
        require(initialAdminMinter != address(0), "adminMinter cannot be zero address");
        __UUPSUpgradeable_init();
        __Ownable_init(owner_);
        _setAdminMinter(initialAdminMinter);
    }

    /// @inheritdoc IMoshiMinter
    function owner() public view override(IMoshiMinter, OwnableUpgradeable) returns (address) {
        return OwnableUpgradeable.owner();
    }

    /// @inheritdoc IMoshiMinter
    function setAdminMinter(address newMinter) external onlyOwner {
        _setAdminMinter(newMinter);
    }

    /// @dev Set the admin minter
    /// @param _newMinter The new admin minter
    function _setAdminMinter(address _newMinter) private {
        require(_newMinter != address(0), "admin minter cannot be zero address");
        _adminMinter = _newMinter;
        emit AdminMinterChanged(_newMinter);
    }

    /// @inheritdoc IMoshiMinter
    function adminMinter() external view override returns (address) {
        return _adminMinter;
    }

    /// @inheritdoc IMoshiMinter
    function setPicImplementation(address pic1155Impl_) external onlyOwner {
        require(pic1155Impl_ != address(0), "pic1155Impl cannot be zero address");
        pic1155Impl = pic1155Impl_;
        emit Pic1155ImplSet(pic1155Impl_);
    }

    /// @inheritdoc IMoshiMinter
    function picImplementation() external view override returns (address) {
        return pic1155Impl;
    }

    /// @dev Restrict upgrade access to owner
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @inheritdoc PermissionCallable
    function supportsPermissionedCallSelector(bytes4 selector) public pure override returns (bool) {
        return selector == MoshiMinterImpl.collectPic.selector || selector == MoshiMinterImpl.mintNewPic.selector;
    }

    /// @inheritdoc IMoshiMinter
    function mintNewPic(
        address to,
        uint256 quantity,
        MoshiPicConfig calldata picConfig,
        MoshiContractConfig calldata contractConfig
    ) external payable picImplementationSet returns (address, uint256) {
        if (msg.sender != contractConfig.owner) {
            revert SenderNotNewContractOwner();
        }
        address pic1155 = _getOrCreatePicContract(contractConfig);
        uint256 id = IMoshiPic1155(pic1155).mint{value: msg.value}(to, quantity, picConfig);
        return (pic1155, id);
    }

    /// @inheritdoc IMoshiMinter
    function mintNewPicAdmin(
        address to,
        uint256 quantity,
        MoshiPicConfig calldata picConfig,
        MoshiContractConfig calldata contractConfig
    ) external onlyAdminMinter picImplementationSet returns (address, uint256) {
        address pic1155 = _getOrCreatePicContract(contractConfig);
        uint256 id = IMoshiPic1155(pic1155).mintAdmin(to, quantity, picConfig);
        return (pic1155, id);
    }

    /// @inheritdoc IMoshiMinter
    function collectPic(address pic1155, address to, uint256 id, uint256 quantity) external payable {
        IMoshiPic1155(pic1155).collect{value: msg.value}(to, id, quantity);
    }

    /// @inheritdoc IMoshiMinter
    function getPicContract(address account) public view virtual returns (address) {
        return picContractOf[account];
    }

    /// @dev Get an existing pic contract or create a new one
    /// @param _config Configuration for the new token and contract
    function _getOrCreatePicContract(MoshiContractConfig calldata _config) internal returns (address picContract) {
        picContract = getPicContract(_config.owner);
        if (picContract == address(0)) {
            picContract = _createPicContract(_config);
        }
    }

    /// @dev Create a new pic contract
    /// Emits `ContractCreated` when a new pic contract is created
    /// @param _config Configuration for the new token and contract
    function _createPicContract(MoshiContractConfig calldata _config) internal returns (address account) {
        account = address(new MoshiPic1155Proxy(pic1155Impl, abi.encodeCall(IMoshiPic1155.initialize, (_config))));
        picContractOf[_config.owner] = account;
        emit NewPicContract(_config.owner, account);
    }
}
