// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IMoshiMinter} from "../src/interfaces/IMoshiMinter.sol";
import {Args, DeployerBase, DeploymentResult} from "./contracts/DeployerBase.sol";
import {Options, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract UpgradeMinter is DeployerBase {
    function run() public {
        address deployer = setDeployer();
        DeploymentResult memory result = readDeployment();

        // Required for session keys
        Options memory opts;
        opts.unsafeAllow = "delegatecall";

        vm.startBroadcast(deployer);
        Upgrades.upgradeProxy(result.minterAddress, "MoshiMinterImpl.sol:MoshiMinterImpl", "", opts);
        vm.stopBroadcast();

        IMoshiMinter(result.minterAddress).owner();
        IMoshiMinter(result.minterAddress).picImplementation();
    }
}
