// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IMoshiBorderRegistry} from "../interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../interfaces/IMoshiMinter.sol";

contract MoshiPic1155Storage {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address payable immutable _moshiWallet;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IMoshiBorderRegistry immutable _borderRegistry;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IMoshiMinter immutable _minter;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint16 immutable _moshiCollectFeeBps;
    // The next token ID to mint
    uint256 _nextTokenId;
    // The price to mint a token
    uint256 _mintPrice;
    // Mapping of token id to border id
    mapping(uint256 => uint256) public borderOf;
    // Mapping of token id to token uid
    mapping(uint256 => string) public tokenUidOf;
    // Reserve extra storage slots
    uint256[50] private __gap;
}
