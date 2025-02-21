// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IMoshiMinter} from "../../src/interfaces/IMoshiMinter.sol";
import {MoshiMinterImpl} from "../../src/minter/MoshiMinterImpl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

library MoshiMinterFixtures {
    // Owner of the minter
    address constant testOwner = address(0xDEAD);
    // Wallet that can admin mint
    address constant testAdminMinter = address(0xBEEF);

    // Create a new minter proxy
    function createMinter() internal returns (IMoshiMinter minter) {
        MoshiMinterImpl minterImpl = new MoshiMinterImpl();
        address proxy = address(
            new ERC1967Proxy(address(minterImpl), abi.encodeCall(minterImpl.initialize, (testOwner, testAdminMinter)))
        );
        minter = IMoshiMinter(proxy);
    }
}
