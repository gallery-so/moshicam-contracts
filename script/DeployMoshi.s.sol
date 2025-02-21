// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Args, DeployerBase} from "./contracts/DeployerBase.sol";
import {DeploymentResult, MoshiDeployer} from "./contracts/MoshiDeployer.sol";
import {SmokeTest} from "./smoke/SmokeTest.sol";
import "forge-std/Script.sol";

/// @notice Deploy Moshi contracts
contract DeployMoshi is DeployerBase, MoshiDeployer, SmokeTest {
    function run() public returns (DeploymentResult memory) {
        address deployer = setDeployer();
        Args memory args = readArgs();

        vm.startBroadcast();
        DeploymentResult memory deployment = deploy(args, deployer);
        writeDeployment(deployment);
        vm.stopBroadcast();

        runForkSmoke(args, deployment, deployer);
        return deployment;
    }
}
