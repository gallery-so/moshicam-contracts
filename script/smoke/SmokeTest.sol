// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiBorderConfig} from "../../src/entities/MoshiBorderConfig.sol";
import {MoshiContractConfig} from "../../src/entities/MoshiContractConfig.sol";
import {MoshiPicConfig} from "../../src/entities/MoshiPicConfig.sol";
import {IMoshiBorderRegistry} from "../../src/interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../../src/interfaces/IMoshiMinter.sol";
import {IMoshiPic1155} from "../../src/interfaces/IMoshiPic1155.sol";
import {MoshiPic1155Impl} from "../../src/pic1155/MoshiPic1155Impl.sol";

import {Args, DeploymentResult} from "../contracts/MoshiDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract SmokeTest is Script, Test {
    function runForkSmoke(Args memory args, DeploymentResult memory deployment, address deployer) public {
        fork(deployment);
        vm.createSelectFork("local");
        smokeRegistry(args, deployment, deployer);
        smokeMinter(args, deployment, deployer);
        smokePic1155(args, deployment, deployer);
    }

    function fork(DeploymentResult memory deployment) private {
        vm.makePersistent(deployment.minterAddress);
        vm.makePersistent(deployment.minterImplementationAddress);
        vm.makePersistent(deployment.borderRegistryAddress);
        vm.makePersistent(deployment.borderRegistryImplementationAddress);
        vm.makePersistent(deployment.pic1155Address);
        vm.makePersistent(deployment.pic1155ImplementationAddress);
    }

    function smokePic1155(Args memory args, DeploymentResult memory deployment, address deployer) public view {
        assertEq(deployer, IMoshiPic1155(deployment.pic1155Address).owner(), "owner should be the deployer");
        assertEq(
            deployment.minterAddress,
            IMoshiPic1155(deployment.pic1155ImplementationAddress).minter(),
            "minter should be the minter contract"
        );
        assertEq(
            deployment.minterAddress,
            IMoshiPic1155(deployment.pic1155ImplementationAddress).minter(),
            "minter should be the minter contract"
        );
        assertEq(
            args.moshiCollectFeeBps,
            IMoshiPic1155(deployment.pic1155ImplementationAddress).moshiCollectFee(),
            "moshi collect fee does not match"
        );
        assertEq(
            args.moshiProtocolWallet,
            IMoshiPic1155(deployment.pic1155ImplementationAddress).moshiWallet(),
            "moshi protocol wallet does not match"
        );
        assertEq(
            deployment.borderRegistryAddress,
            IMoshiPic1155(deployment.pic1155ImplementationAddress).borderRegistry(),
            "border registry should be the border registry contract"
        );
    }

    function smokeRegistry(Args memory args, DeploymentResult memory deployment, address deployer) public {
        address borderCreator = makeAddr("borderCreator");
        IMoshiBorderRegistry registry = IMoshiBorderRegistry(deployment.borderRegistryAddress);
        MoshiBorderConfig memory borderConfig1;
        borderConfig1.creator = borderCreator;
        borderConfig1.creatorFeeBps = 2000;
        MoshiBorderConfig memory borderConfig2;
        borderConfig2.creator = makeAddr("borderCreator2");
        borderConfig2.creatorFeeBps = 5000;

        vm.startPrank(deployer);
        (uint256 borderId1) = registry.addBorder(borderConfig1);
        (uint256 borderId2) = registry.addBorder(borderConfig1);
        registry.updateBorder(borderId2, borderConfig2);
        vm.stopPrank();

        assertEq(deployer, registry.owner(), "owner should be the deployer");
        assertTrue(registry.exists(0), "default border should exist");
        assertEq(
            args.moshiProtocolWallet,
            registry.getBorder(0).creator,
            "creator of default border should be the moshi protocol wallet"
        );
        assertEq(2000, registry.getBorder(0).creatorFeeBps, "default border should have a creator fee");
        assertTrue(registry.exists(borderId1), "new border should exist");
        assertEq(
            keccak256(abi.encode(borderConfig1)),
            keccak256(abi.encode(registry.getBorder(borderId1))),
            "border config should match"
        );
        assertEq(
            keccak256(abi.encode(borderConfig2)),
            keccak256(abi.encode(registry.getBorder(borderId2))),
            "border config was not updated"
        );
    }

    function smokeMinter(Args memory args, DeploymentResult memory deployment, address deployer) public {
        // Given
        address user = makeAddr("user");
        address collector = makeAddr("collector");
        vm.deal(user, 100 ether);
        vm.deal(args.adminMinterWallet, 100 ether);
        vm.deal(collector, 100 ether);
        address borderCreator = makeAddr("borderCreator");
        MoshiBorderConfig memory borderConfig;
        borderConfig.creator = borderCreator;
        borderConfig.creatorFeeBps = 2000;
        vm.prank(deployer);
        uint256 borderId = IMoshiBorderRegistry(deployment.borderRegistryAddress).addBorder(borderConfig);
        MoshiPicConfig memory picConfig = MoshiPicConfig({borderId: borderId, tokenUid: "some-uid"});
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: user, mintPrice: 0.1 ether});

        // Mint as user
        hoax(user, 100 ether);
        (address picContract, uint256 tokenId1) =
            IMoshiMinter(deployment.minterAddress).mintNewPic{value: 0.1 ether}(user, 1, picConfig, contractConfig);
        // Mint as admin
        hoax(args.adminMinterWallet, 100 ether);
        (, uint256 tokenId2) =
            IMoshiMinter(deployment.minterAddress).mintNewPicAdmin(user, 1, picConfig, contractConfig);
        // Collect as collector
        hoax(collector, 100 ether);
        IMoshiPic1155(picContract).collect{value: 0.1 ether}(collector, tokenId1, 1);
        // Collect through minter
        IMoshiMinter(deployment.minterAddress).collectPic{value: 0.1 ether}(picContract, collector, tokenId2, 1);
        // Withdraw fees as user
        vm.prank(user);
        uint256 balanceBeforeWithdraw = user.balance;
        IMoshiPic1155(picContract).withdraw();

        // Then
        IMoshiPic1155 pic = IMoshiPic1155(picContract);
        assertEq(
            args.adminMinterWallet,
            IMoshiMinter(deployment.minterAddress).adminMinter(),
            "admin minter does not match input"
        );
        assertEq(deployer, IMoshiMinter(deployment.minterAddress).owner(), "minter owner should be the deployer");
        assertEq(user, IMoshiPic1155(picContract).owner(), "owner of pic contract should be the user");
        assertEq(args.moshiCollectFeeBps, pic.moshiCollectFee(), "moshi collect fee does not match");
        assertEq(7172968000000000, tokenId1, "expected tokenId1 to start from startPrefixTokenId");
        assertEq(1, pic.balanceOf(user, tokenId1), "balance of user should be 1");
        assertEq(1, pic.balanceOf(user, tokenId2), "balance of user should be 1");
        assertEq(1, pic.balanceOf(collector, tokenId1), "balance of collector should be 1");
        assertEq(1, pic.balanceOf(collector, tokenId2), "balance of collector should be 1");
        assertEq(4, pic.totalSupply(), "total supply should be 4");
        assertEq(2, pic.totalSupply(tokenId1), "total supply of tokenId1 should be 2");
        assertEq(2, pic.totalSupply(tokenId2), "total supply of tokenId2 should be 1");
        assertEq(
            picContract, IMoshiMinter(deployment.minterAddress).getPicContract(user), "pic contract does not match"
        );
        assertNotEq("", pic.uri(tokenId1), "uri should not be empty");
        assertGt(args.moshiProtocolWallet.balance, 0, "moshi protocol wallet should have some balance");
        assertGt(borderCreator.balance, 0, "border creator should have some balance");
        assertEq(0, picContract.balance, "pic balance should be 0 after withdraw");
        assertGt(user.balance, balanceBeforeWithdraw, "user balance should be greater after withdraw");
        assertTrue(MoshiPic1155Impl(picContract).usingPrefixedScheme(), "pic should be using prefixed scheme");
    }
}
