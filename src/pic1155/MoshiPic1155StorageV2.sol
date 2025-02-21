// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IMoshiBorderRegistry} from "../interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../interfaces/IMoshiMinter.sol";

contract MoshiPic1155StorageV2 {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address payable immutable _moshiWallet;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IMoshiBorderRegistry immutable _borderRegistry;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IMoshiMinter immutable _minter;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint16 immutable _moshiCollectFeeBps;
    // Deprecated: Only used for old contracts. Use `_prefixedNextTokenId` instead
    // The next token ID to mint
    uint256 _nextTokenId;
    // The price to mint a token
    uint256 _mintPrice;
    // Mapping of token id to border id
    mapping(uint256 => uint256) public borderOf;
    // Mapping of token id to token uid
    mapping(uint256 => string) public tokenUidOf;
    // The starting token ID for token ids with a prefix
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 immutable _startPrefixedTokenId;
    // The next token ID to mint, prefixed with a moshi token identifier
    uint256 _prefixedNextTokenId;
    // Reserve extra storage slots
    uint256[49] private __gap;
}
