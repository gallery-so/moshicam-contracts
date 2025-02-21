// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiBorderConfig} from "../../src/entities/MoshiBorderConfig.sol";
import {IMoshiBorderRegistry} from "../../src/interfaces/IMoshiBorderRegistry.sol";
import {MoshiBorderRegistry} from "../../src/registry/MoshiBorderRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

library MoshiBorderRegistryFixtures {
    address constant testBorderCreator = address(123);
    uint16 constant testCreatorFeeBps = 2000;

    function createBorderRegistry() internal returns (IMoshiBorderRegistry registry) {
        MoshiBorderRegistry registry_ = new MoshiBorderRegistry();
        MoshiBorderConfig memory defaultConfig =
            MoshiBorderConfig({creator: testBorderCreator, creatorFeeBps: testCreatorFeeBps});
        registry = IMoshiBorderRegistry(
            address(
                new ERC1967Proxy(address(registry_), abi.encodeCall(MoshiBorderRegistry.initialize, (defaultConfig)))
            )
        );
    }
}
