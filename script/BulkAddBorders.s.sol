// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiBorderConfig} from "../src/entities/MoshiBorderConfig.sol";
import {IMoshiBorderRegistry} from "../src/interfaces/IMoshiBorderRegistry.sol";
import {DeployerBase} from "./contracts/DeployerBase.sol";
import {DeploymentResult} from "./contracts/DeployerBase.sol";
import "forge-std/Script.sol";

struct NewMoshiBorder {
    address creator;
    uint16 creatorFeeBps;
    string name;
    string url;
}

/// @notice Script to add many borders to the registry
/// @dev Run via: forge script --rpc-url <env> --broadcast BulkAddBorders --sig "run(string,string)" -- ./border_configs.json ./border_result.sql
/// See `foundry.toml` for available envs
contract BulkAddBorders is DeployerBase {
    using stdJson for string;

    /// @notice Add many borders to the registry
    /// @dev Borders are added to the registry address defined in the `deployments` dir
    /// @param borderFile The path to json-formatted array of border configurations to add
    /// @param outFile The file path to write the results
    function run(string calldata borderFile, string calldata outFile) public {
        NewMoshiBorder[] memory bordersToAdd = readBorders(borderFile);
        address deployer = setDeployer();

        vm.startBroadcast(deployer);
        uint256[] memory newBorderIds = addBorders(bordersToAdd);
        vm.stopBroadcast();

        writeBorders(bordersToAdd, newBorderIds, outFile);
    }

    /// @dev Read the borders from a file
    /// @param borderFile The path to json-formatted array of border configurations to add
    function readBorders(string calldata borderFile) private view returns (NewMoshiBorder[] memory bordersToAdd) {
        string memory json = vm.readFile(borderFile);
        bytes memory data = vm.parseJson(json);
        bordersToAdd = abi.decode(data, (NewMoshiBorder[]));
    }

    function addBorders(NewMoshiBorder[] memory bordersToAdd) public returns (uint256[] memory) {
        DeploymentResult memory deployment = readDeployment();
        IMoshiBorderRegistry registry = IMoshiBorderRegistry(deployment.borderRegistryAddress);
        MoshiBorderConfig[] memory newBorders = new MoshiBorderConfig[](bordersToAdd.length);

        for (uint256 i = 0; i < bordersToAdd.length; i++) {
            MoshiBorderConfig memory border =
                MoshiBorderConfig({creator: bordersToAdd[i].creator, creatorFeeBps: bordersToAdd[i].creatorFeeBps});
            newBorders[i] = border;
        }

        return registry.addBorders(newBorders);
    }

    /// @dev Write the new borders to `outFile`
    /// @param bordersToAdd The borders to write
    /// @param newBorderIds The ids of the new borders
    /// @param outFile The file path to write the results
    function writeBorders(NewMoshiBorder[] memory bordersToAdd, uint256[] memory newBorderIds, string calldata outFile)
        private
    {
        require(bordersToAdd.length == newBorderIds.length, "length of added borders does not match input");

        if (vm.isFile(outFile)) {
            vm.removeFile(outFile);
        }

        for (uint256 i = 0; i < bordersToAdd.length; i++) {
            vm.writeLine(
                outFile,
                string.concat(
                    "insert into borders(id,border_id,creator_address,name,image_url) values (",
                    "ksuid()",
                    ",",
                    vm.toString(newBorderIds[i]),
                    ",",
                    string.concat("lower(", "'", vm.toString(bordersToAdd[i].creator), "'", ")"),
                    ",",
                    string.concat("'", bordersToAdd[i].name, "'"),
                    ",",
                    string.concat("'", bordersToAdd[i].url, "'"),
                    ");"
                )
            );
        }
    }
}
