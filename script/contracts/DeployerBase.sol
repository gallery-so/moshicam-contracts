// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Logger} from "./Logger.sol";
import "forge-std/Script.sol";

struct Args {
    address adminMinterWallet;
    address payable moshiProtocolWallet;
    uint16 moshiCollectFeeBps;
    uint256 startPrefixedTokenId;
}

struct DeploymentResult {
    address borderRegistryAddress;
    address borderRegistryImplementationAddress;
    address minterAddress;
    address minterImplementationAddress;
    address pic1155Address;
    address pic1155ImplementationAddress;
}

/// @title Base contract for deploying contracts
contract DeployerBase is Script, Logger {
    using stdJson for string;

    string constant CONFIG_DIR = "config";
    string constant CONFIG_FILE_NAME = "config.json";
    string constant ADMIN_MINTER_WALLET_ADDRESS_KEY = "ADMIN_MINTER_WALLET_ADDRESS";
    string constant MOSHI_COLLECT_FEE_BPS_KEY = "MOSHI_COLLECT_FEE_BPS";
    string constant MOSHI_PROTOCOL_WALLET_ADDRESS_KEY = "MOSHI_PROTOCOL_WALLET_ADDRESS";
    string constant START_PREFIXED_TOKEN_ID_KEY = "START_PREFIXED_TOKEN_ID";

    string constant DEPLOYMENTS_DIR = "deployments";
    string constant DEPLOYMENT_RESULT_FILE_NAME = "result.json";
    string constant BORDER_REGISTRY_ADDRESS_KEY = "BORDER_REGISTRY_ADDRESS";
    string constant MINTER_ADDRESS_KEY = "MINTER_ADDRESS";
    string constant PIC1155_ADDRESS_KEY = "PIC1155_ADDRESS";

    /// @dev Sets the deployer address for broadcasting
    function setDeployer() public returns (address deployer) {
        string memory _input = vm.promptSecret("Provide private key of deployer wallet [input is hidden]");
        uint256 deployerPK = vm.parseUint(_input);

        deployer = vm.addr(deployerPK);
        vm.label(deployer, "deployer");

        string memory confirm = vm.prompt(string.concat("Is ", emphasize(deployer), " the correct address? (Y/n)"));

        if (keccak256(abi.encodePacked(confirm)) != keccak256(abi.encodePacked("Y"))) {
            revert("deployer address is incorrect");
        }

        vm.rememberKey(deployerPK);
    }

    /// @dev Read configuration from file in `CONFIG_DIR` directory
    function readArgs() public view returns (Args memory) {
        string memory config = vm.readFile(configPath());
        return Args({
            adminMinterWallet: config.readAddress(string.concat(".", ADMIN_MINTER_WALLET_ADDRESS_KEY)),
            moshiCollectFeeBps: uint16(config.readUint(string.concat(".", MOSHI_COLLECT_FEE_BPS_KEY))),
            moshiProtocolWallet: payable(config.readAddress(string.concat(".", MOSHI_PROTOCOL_WALLET_ADDRESS_KEY))),
            startPrefixedTokenId: uint256(config.readUint(string.concat(".", START_PREFIXED_TOKEN_ID_KEY)))
        });
    }

    /// @dev Read deployment result from file in `DEPLOYMENTS_DIR` directory
    function readDeployment() public view returns (DeploymentResult memory result) {
        string memory deployment = vm.readFile(deploymentResultPath());
        result.borderRegistryAddress = deployment.readAddress(string.concat(".", BORDER_REGISTRY_ADDRESS_KEY));
        result.minterAddress = deployment.readAddress(string.concat(".", MINTER_ADDRESS_KEY));
        result.pic1155Address = deployment.readAddress(string.concat(".", PIC1155_ADDRESS_KEY));
    }

    /// @dev Write deployment result to file in `DEPLOYMENTS_DIR` directory
    /// @param result The deployment result to write
    function writeDeployment(DeploymentResult memory result) public {
        string memory out = "deploymentResult";
        vm.serializeAddress(out, MINTER_ADDRESS_KEY, result.minterAddress);
        vm.serializeAddress(out, BORDER_REGISTRY_ADDRESS_KEY, result.borderRegistryAddress);
        string memory out_ = vm.serializeAddress(out, PIC1155_ADDRESS_KEY, result.pic1155Address);
        mkDir(deploymentResultDir());
        vm.writeJson(out_, deploymentResultPath());
    }

    /// @dev Create a directory. Requires ffi enabled.
    function mkDir(string memory dir) private {
        if (vm.isDir(dir)) {
            return;
        }
        string[] memory args = new string[](3);
        args[0] = "mkdir";
        args[1] = "-p";
        args[2] = dir;
        vm.ffi(args);
    }

    function configPath() private view returns (string memory) {
        return string.concat(vm.projectRoot(), "/", CONFIG_DIR, "/", vm.toString(block.chainid), "/", CONFIG_FILE_NAME);
    }

    function deploymentResultDir() private view returns (string memory) {
        return string.concat(vm.projectRoot(), "/", DEPLOYMENTS_DIR, "/", vm.toString(block.chainid));
    }

    function deploymentResultPath() private view returns (string memory) {
        return string.concat(deploymentResultDir(), "/", DEPLOYMENT_RESULT_FILE_NAME);
    }
}
