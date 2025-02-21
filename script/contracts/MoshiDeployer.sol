// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiBorderConfig} from "../../src/entities/MoshiBorderConfig.sol";
import {MoshiSharedSettings} from "../../src/entities/MoshiSharedSettings.sol";
import {IMoshiBorderRegistry} from "../../src/interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../../src/interfaces/IMoshiMinter.sol";
import {MoshiMinterImpl} from "../../src/minter/MoshiMinterImpl.sol";

import {MoshiMinterProxy} from "../../src/minter/MoshiMinterProxy.sol";
import {MoshiPic1155Beacon} from "../../src/pic1155/MoshiPic1155Beacon.sol";
import {MoshiPic1155Impl} from "../../src/pic1155/MoshiPic1155Impl.sol";
import {MoshiBorderRegistry} from "../../src/registry/MoshiBorderRegistry.sol";
import {MoshiBorderRegistryProxy} from "../../src/registry/MoshiBorderRegistryProxy.sol";

import {Args, DeploymentResult} from "./DeployerBase.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Script} from "forge-std/Script.sol";

/// @title Deploy new set of Moshi contracts
contract MoshiDeployer is Script {
    bytes32 MINTER_SALT = keccak256(bytes("MoshiCam.MoshiMinter"));

    /// @dev Deploy Moshi contracts
    /// @param args Deployment arguments
    function deploy(Args memory args, address deployer) public returns (DeploymentResult memory) {
        (address borderRegistry, address borderRegistryImpl) = deployBorderRegistryProxy(args);
        (address computedMinterAddress, address minterImpl, bytes memory minterCreationCode) =
            computeMinterAddress(args, deployer);
        (address pic1155, address pic1155Implementation) =
            deployPic1155Beacon(args, borderRegistry, computedMinterAddress, deployer);
        address minter = deployMinterProxy(computedMinterAddress, minterCreationCode);

        // Register the minter with the pic1155 beacon
        IMoshiMinter(minter).setPicImplementation(pic1155);

        return DeploymentResult({
            minterAddress: minter,
            minterImplementationAddress: minterImpl,
            borderRegistryAddress: borderRegistry,
            borderRegistryImplementationAddress: borderRegistryImpl,
            pic1155Address: pic1155,
            pic1155ImplementationAddress: pic1155Implementation
        });
    }

    /// @dev Compute the address of the minter contract
    /// @param args Deployment arguments
    /// @param deployer Address of the deployer. Used as the owner of the minter contract.
    function computeMinterAddress(Args memory args, address deployer)
        public
        returns (address computedAddress, address implementation, bytes memory creationCode)
    {
        implementation = address(new MoshiMinterImpl());
        creationCode = abi.encodePacked(
            type(MoshiMinterProxy).creationCode,
            abi.encode(implementation, abi.encodeCall(MoshiMinterImpl.initialize, (deployer, args.adminMinterWallet)))
        );
        computedAddress = vm.computeCreate2Address(MINTER_SALT, keccak256(creationCode));
    }

    function deployPic1155Beacon(Args memory args, address borderRegistry, address minterAddress, address deployer)
        public
        returns (address proxy, address implementation)
    {
        implementation = address(
            new MoshiPic1155Impl(
                MoshiSharedSettings({
                    moshiWallet: args.moshiProtocolWallet,
                    borderRegistry: IMoshiBorderRegistry(borderRegistry),
                    minter: IMoshiMinter(minterAddress),
                    moshiCollectFeeBps: args.moshiCollectFeeBps,
                    startPrefixedTokenId: args.startPrefixedTokenId
                })
            )
        );
        proxy = address(new MoshiPic1155Beacon(implementation, deployer));
    }

    /// @dev Deploy proxy to MoshiMinterImpl contract
    function deployMinterProxy(address computedMinterAddress, bytes memory minterCreationCode)
        public
        returns (address deployed)
    {
        deployed = Create2.deploy(0, MINTER_SALT, minterCreationCode);
        require(computedMinterAddress == deployed, "deployed minter address does not match computed");
    }

    /// @dev Deploy proxy to MoshiBorderRegistry contract
    function deployBorderRegistryProxy(Args memory args) public returns (address proxy, address implementation) {
        // Set up the default border
        MoshiBorderConfig memory defaultBorderConfig;
        defaultBorderConfig.creator = args.moshiProtocolWallet;
        defaultBorderConfig.creatorFeeBps = 2000;
        implementation = address(new MoshiBorderRegistry());
        proxy = address(
            new MoshiBorderRegistryProxy(
                implementation, abi.encodeCall(MoshiBorderRegistry.initialize, (defaultBorderConfig))
            )
        );
    }
}
