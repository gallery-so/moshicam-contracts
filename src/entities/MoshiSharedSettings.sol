// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IMoshiBorderRegistry} from "../interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../interfaces/IMoshiMinter.sol";

struct MoshiSharedSettings {
    // The address of the Moshi wallet
    address payable moshiWallet;
    // The address of the Moshi border registry
    IMoshiBorderRegistry borderRegistry;
    // The address of the Moshi minter
    IMoshiMinter minter;
    // The moshi protocol fee in basis points
    uint16 moshiCollectFeeBps;
    // The starting token ID for token ids with a prefix
    uint256 startPrefixedTokenId;
}
