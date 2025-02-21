// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiBorderConfig} from "../entities/MoshiBorderConfig.sol";
import {MoshiContractConfig} from "../entities/MoshiContractConfig.sol";
import {MoshiPicConfig} from "../entities/MoshiPicConfig.sol";
import {MoshiSharedSettings} from "../entities/MoshiSharedSettings.sol";
import {IMoshiBorderRegistry} from "../interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../interfaces/IMoshiMinter.sol";
import {IMoshiPic1155} from "../interfaces/IMoshiPic1155.sol";
import {MoshiFeeSplit} from "../splits/MoshiFeeSplit.sol";
import {MoshiPic1155StorageV2} from "./MoshiPic1155StorageV2.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ERC1155SupplyUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @title The implementation contract for a creator's MoshiPic1155
contract MoshiPic1155Impl is
    Initializable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155SupplyUpgradeable,
    MoshiPic1155StorageV2,
    IMoshiPic1155
{
    /// @notice Reverts if `msg.sender` is not the minter
    modifier onlyMinter() {
        require(msg.sender == address(_minter), "only minter");
        _;
    }

    /// @notice Reverts if the token id does not exist
    /// @param _id The token id
    modifier tokenIdExists(uint256 _id) {
        if (!usingPrefixedScheme()) {
            if (_id >= _nextTokenId) {
                revert TokenIdDoesNotExist(_id);
            }
            _;
            return;
        }
        if (_id < _startPrefixedTokenId || _id >= _prefixedNextTokenId) {
            revert TokenIdDoesNotExist(_id);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @param settings The protocol settings
    constructor(MoshiSharedSettings memory settings) {
        require(settings.moshiWallet != address(0), "moshiWallet cannot be zero address");
        require(address(settings.borderRegistry) != address(0), "borderRegistry cannot be zero address");
        require(address(settings.minter) != address(0), "minter cannot be zero address");
        require(settings.startPrefixedTokenId != 0, "startPrefixedTokenId cannot be zero");
        _moshiWallet = settings.moshiWallet;
        _borderRegistry = settings.borderRegistry;
        _minter = settings.minter;
        _moshiCollectFeeBps = settings.moshiCollectFeeBps;
        _startPrefixedTokenId = settings.startPrefixedTokenId;
        _disableInitializers();
    }

    /// @notice Initialize proxy
    /// @param config The initial contract configuration
    function initialize(MoshiContractConfig calldata config) public initializer {
        require(config.owner != address(0), "owner cannot be zero address");
        __Ownable_init(config.owner);
        __ReentrancyGuard_init();
        _nextTokenId = 0;
        _prefixedNextTokenId = _startPrefixedTokenId;
        _mintPrice = config.mintPrice;
    }

    /// @inheritdoc IMoshiPic1155
    function name() external pure returns (string memory) {
        return "Moshicam";
    }

    /// @inheritdoc IMoshiPic1155
    function symbol() external pure returns (string memory) {
        return "MOSHICAM";
    }

    /// @inheritdoc IMoshiPic1155
    function totalSupply() public view override(ERC1155SupplyUpgradeable, IMoshiPic1155) returns (uint256) {
        return ERC1155SupplyUpgradeable.totalSupply();
    }

    /// @inheritdoc IMoshiPic1155
    function totalSupply(uint256 id) public view override(ERC1155SupplyUpgradeable, IMoshiPic1155) returns (uint256) {
        return ERC1155SupplyUpgradeable.totalSupply(id);
    }

    /// @inheritdoc IMoshiPic1155
    function owner() public view override(OwnableUpgradeable, IMoshiPic1155) returns (address) {
        return OwnableUpgradeable.owner();
    }

    /// @inheritdoc IMoshiPic1155
    function mint(address to, uint256 quantity, MoshiPicConfig calldata config)
        external
        payable
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(msg.value >= _mintPrice * quantity, "insufficient ether sent");
        (uint256 id, MoshiBorderConfig memory border) = _mintNew(to, quantity, config);
        MoshiFeeSplit.split(
            _moshiWallet, MoshiFeeSplit.ONE_HUNDRED_PCT_BPS - border.creatorFeeBps, border.creator, border.creatorFeeBps
        );
        return id;
    }

    /// @inheritdoc IMoshiPic1155
    function mintAdmin(address to, uint256 quantity, MoshiPicConfig calldata config)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        (uint256 id,) = _mintNew(to, quantity, config);
        return id;
    }

    /// @dev Mint a new token
    /// Emits a `MoshiCreated` event.
    /// @param to The address to mint to
    /// @param quantity The amount to mint
    /// @param config The token configuration
    function _mintNew(address to, uint256 quantity, MoshiPicConfig calldata config)
        private
        onlyMinter
        returns (uint256 id, MoshiBorderConfig memory border)
    {
        (id, border) = _initializeToken(config);
        _mintToken(to, id, quantity);
        emit MoshiCreated(to, id, config.borderId, quantity);
    }

    /// @notice Initialize a new token
    /// @dev Reverts with `MoshiBorderRegistry.ErrBorderUnknown` if border does not exist
    /// @param config The token configuration
    function _initializeToken(MoshiPicConfig calldata config)
        private
        returns (uint256 id, MoshiBorderConfig memory border)
    {
        if (bytes(config.tokenUid).length == 0) {
            revert InvalidPicConfiguration("tokenUid is empty");
        }
        border = _borderRegistry.getBorder(config.borderId);

        if (!usingPrefixedScheme()) {
            id = _nextTokenId;
            _nextTokenId++;
        } else {
            id = _prefixedNextTokenId;
            _prefixedNextTokenId++;
        }

        borderOf[id] = config.borderId;
        tokenUidOf[id] = config.tokenUid;
    }

    /// @inheritdoc IMoshiPic1155
    function collect(address to, uint256 id, uint256 quantity) external payable nonReentrant {
        require(msg.value >= _mintPrice * quantity, "insufficient ether sent");
        _mintToken(to, id, quantity);
        MoshiBorderConfig memory border = _borderRegistry.getBorder(borderOf[id]);
        MoshiFeeSplit.split(_moshiWallet, _moshiCollectFeeBps, border.creator, border.creatorFeeBps);
        emit MoshiCollected(to, id, borderOf[id], quantity);
    }

    /// @dev Mint a token to `_to`
    /// @param _to The address to mint to
    /// @param _id The id of the token to mint
    /// @param _quantity The amount to mint
    function _mintToken(address _to, uint256 _id, uint256 _quantity) private tokenIdExists(_id) {
        require(_quantity > 0, "quantity must be greater than 0");
        _mint(_to, _id, _quantity, "");
    }

    /// @inheritdoc IMoshiPic1155
    function uri(uint256 id)
        public
        view
        virtual
        override(ERC1155Upgradeable, IMoshiPic1155)
        tokenIdExists(id)
        returns (string memory)
    {
        return string(abi.encodePacked("https://api.moshi.cam/api/v1/metadata/", tokenUidOf[id], ".json"));
    }

    /// @inheritdoc IMoshiPic1155
    function borderId(uint256 id) external view returns (uint256) {
        return borderOf[id];
    }

    /// @dev Return true if contract is using the prefixed token id scheme
    function usingPrefixedScheme() public view returns (bool) {
        // `_prefixedNextTokenId` initialized for new contracts
        return _prefixedNextTokenId != 0;
    }

    /// @inheritdoc IMoshiPic1155
    function nextTokenId() external view returns (uint256) {
        if (!usingPrefixedScheme()) {
            return _nextTokenId;
        }
        return _prefixedNextTokenId;
    }

    /// @inheritdoc IMoshiPic1155
    function moshiWallet() external view returns (address) {
        return _moshiWallet;
    }

    /// @inheritdoc IMoshiPic1155
    function borderRegistry() external view returns (address) {
        return address(_borderRegistry);
    }

    /// @inheritdoc IMoshiPic1155
    function minter() external view returns (address) {
        return address(_minter);
    }

    /// @inheritdoc IMoshiPic1155
    function mintPrice() external view override returns (uint256) {
        return _mintPrice;
    }

    /// @inheritdoc IMoshiPic1155
    function moshiCollectFee() external view override returns (uint16) {
        return _moshiCollectFeeBps;
    }

    /// @inheritdoc IMoshiPic1155
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        address owner_ = owner();
        (bool success,) = owner_.call{value: balance}("");
        require(success, "withdraw failed");
        emit Withdraw(owner_, balance);
    }
}
