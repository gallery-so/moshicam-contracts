// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiBorderConfig} from "../src/entities/MoshiBorderConfig.sol";
import {IMoshiBorderRegistry} from "../src/interfaces/IMoshiBorderRegistry.sol";
import {DeployerBase} from "./contracts/DeployerBase.sol";
import {DeploymentResult} from "./contracts/DeployerBase.sol";
import "forge-std/Script.sol";

/// @notice Script to add a new border to the registry
contract AddBorder is Script, DeployerBase {
    /// @notice Add a new border to the registry
    /// @dev Border is added to the registry address defined in the `deployments` dir
    /// @return newBorderId The new border id
    function run() public returns (uint256 newBorderId) {
        DeploymentResult memory deployment = readDeployment();
        IMoshiBorderRegistry registry = IMoshiBorderRegistry(deployment.borderRegistryAddress);

        address deployer = setDeployer();

        address borderCreator = vm.promptAddress("Provide address of the border creator");
        vm.label(borderCreator, "creator");

        string memory confirm =
            vm.prompt(string.concat("Adding new border with creator ", emphasize(borderCreator), ". Confirm? (Y/n)"));

        if (keccak256(abi.encodePacked(confirm)) != keccak256(abi.encodePacked("Y"))) {
            revert("canceled adding border");
        }

        vm.startBroadcast(deployer);
        newBorderId = registry.addBorder(MoshiBorderConfig({creator: borderCreator, creatorFeeBps: 2000}));
        vm.stopBroadcast();

        console.log("Added new border with id:", newBorderId);
    }
}
