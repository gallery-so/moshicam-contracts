// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiSharedSettings} from "../src/entities/MoshiSharedSettings.sol";
import {IMoshiBorderRegistry} from "../src/interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../src/interfaces/IMoshiMinter.sol";
import {IMoshiPic1155} from "../src/interfaces/IMoshiPic1155.sol";
import {MoshiPic1155Impl} from "../src/pic1155/MoshiPic1155Impl.sol";
import {Args, DeployerBase, DeploymentResult} from "./contracts/DeployerBase.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "forge-std/Test.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/// @notice Upgrade MoshiPic1155 beacon to latest implementation
contract UpgradeMoshiPic is DeployerBase {
    function run() public {
        address deployer = setDeployer();
        DeploymentResult memory result = readDeployment();
        Args memory args = readArgs();

        Options memory opts;
        opts.constructorData = abi.encodePacked(
            abi.encode(
                MoshiSharedSettings({
                    moshiWallet: args.moshiProtocolWallet,
                    borderRegistry: IMoshiBorderRegistry(result.borderRegistryAddress),
                    minter: IMoshiMinter(result.minterAddress),
                    moshiCollectFeeBps: args.moshiCollectFeeBps,
                    startPrefixedTokenId: args.startPrefixedTokenId
                })
            )
        );

        vm.startBroadcast(deployer);
        Upgrades.upgradeBeacon(result.pic1155Address, "MoshiPic1155Impl.sol:MoshiPic1155Impl", opts);
        vm.stopBroadcast();

        address implementation = address(IBeacon(result.pic1155Address).implementation());
        vm.assertEq("Moshicam", IMoshiPic1155(implementation).name());
        vm.assertEq("MOSHICAM", IMoshiPic1155(implementation).symbol());
        MoshiPic1155Impl(implementation).usingPrefixedScheme();
    }
}
