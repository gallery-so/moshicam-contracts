// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {Proxiable} from "../../lib/openzeppelin-foundry-upgrades/test/contracts/Proxiable.sol";
import {MoshiBorderConfig} from "../../src/entities/MoshiBorderConfig.sol";
import {IMoshiBorderRegistry} from "../../src/interfaces/IMoshiBorderRegistry.sol";
import {MoshiBorderRegistry} from "../../src/registry/MoshiBorderRegistry.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MoshiBorderRegistryTest is Test {
    MoshiBorderRegistry registry = new MoshiBorderRegistry();
    MoshiBorderConfig defaultConfig = MoshiBorderConfig({creator: payable(address(123)), creatorFeeBps: 2000});
    bytes proxyInit = abi.encodeCall(MoshiBorderRegistry.initialize, (defaultConfig));

    function test_exists_NonExistentBorder() public view {
        assertFalse(IMoshiBorderRegistry(address(registry)).exists(123));
    }

    function test_exists_ExistentBorder() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        uint256 id = MoshiBorderRegistry(proxy).addBorder(defaultConfig);

        assertTrue(IMoshiBorderRegistry(proxy).exists(id));
    }

    function test_initialize_AddsDefaultBorder() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));

        assertTrue(IMoshiBorderRegistry(proxy).exists(0));
    }

    function test_addBorder_OnlyOwnerCanAdd() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));

        IMoshiBorderRegistry(proxy).addBorder(defaultConfig);
    }

    function test_addBorder_AddsBorder() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        IMoshiBorderRegistry _registry = IMoshiBorderRegistry(proxy);

        uint256 firstId = _registry.addBorder(defaultConfig);
        uint256 secondId = _registry.addBorder(defaultConfig);
        _registry.getBorder(firstId);
        _registry.getBorder(secondId);

        assertEq(1, firstId, "unexpected id");
        assertEq(2, secondId, "unexpected id");
        assertEq(3, MoshiBorderRegistry(proxy).nextBorderId(), "unexpected next border id");
    }

    function test_addBorder_CannotAddBorderWithZeroAddressCreator() public {
        vm.prank(registry.owner());

        vm.expectRevert(IMoshiBorderRegistry.InvalidBorderCreator.selector);

        registry.addBorder(MoshiBorderConfig({creator: address(0), creatorFeeBps: 2000}));
    }

    function test_addBorders_OnlyOwnerCanAdd() public {
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));

        MoshiBorderConfig[] memory configs = new MoshiBorderConfig[](0);

        IMoshiBorderRegistry(registry).addBorders(configs);
    }

    function test_addBorders_AddsBorders() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        IMoshiBorderRegistry _registry = IMoshiBorderRegistry(proxy);
        MoshiBorderConfig[] memory configs = new MoshiBorderConfig[](3);
        configs[0] = MoshiBorderConfig({creator: payable(address(123)), creatorFeeBps: 1000});
        configs[1] = MoshiBorderConfig({creator: payable(address(456)), creatorFeeBps: 2000});
        configs[2] = MoshiBorderConfig({creator: payable(address(789)), creatorFeeBps: 3000});

        uint256[] memory newBorderIds = _registry.addBorders(configs);

        assertEq(configs.length, newBorderIds.length, "expected same length");
        assertEq(1, newBorderIds[0], "expected id to be 1");
        assertEq(2, newBorderIds[1], "expected id to be 2");
        assertEq(3, newBorderIds[2], "expected id to be 3");
        assertEq(
            keccak256(abi.encode(configs[0])), keccak256(abi.encode(_registry.getBorder(1))), "border 1 config mismatch"
        );
        assertEq(
            keccak256(abi.encode(configs[1])), keccak256(abi.encode(_registry.getBorder(2))), "border 2 config mismatch"
        );
        assertEq(
            keccak256(abi.encode(configs[2])), keccak256(abi.encode(_registry.getBorder(3))), "border 3 config mismatch"
        );
        assertEq(4, MoshiBorderRegistry(proxy).nextBorderId(), "unexpected next border id");
    }

    function test_addBorders_CannotAddBorderWithZeroAddressCreator() public {
        MoshiBorderConfig[] memory configs = new MoshiBorderConfig[](1);
        configs[0] = MoshiBorderConfig({creator: payable(address(0)), creatorFeeBps: 1000});
        uint256 curNextBorderId = registry.nextBorderId();
        vm.prank(registry.owner());

        vm.expectRevert(IMoshiBorderRegistry.InvalidBorderCreator.selector);

        registry.addBorders(configs);

        assertEq(curNextBorderId, registry.nextBorderId(), "next border id should not changed on revert");
    }

    function test_updateBorder_OnlyOwnerCanUpdate() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));

        IMoshiBorderRegistry(proxy).updateBorder(1, defaultConfig);
    }

    function test_updateBorder_UpdatesBorder() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        MoshiBorderConfig memory newConfig;
        newConfig.creator = payable(address(123));
        uint256 curNextBorderId = IMoshiBorderRegistry(proxy).nextBorderId();

        IMoshiBorderRegistry(proxy).updateBorder(0, newConfig);

        MoshiBorderConfig memory actual = IMoshiBorderRegistry(proxy).getBorder(0);
        assertEq(keccak256(abi.encode(newConfig)), keccak256(abi.encode(actual)));
        assertEq(
            curNextBorderId, IMoshiBorderRegistry(proxy).nextBorderId(), "next border id should not changed on update"
        );
    }

    function test_updateBorder_CanOnlyUpdateExistingBorder() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        MoshiBorderConfig memory newConfig;

        vm.expectRevert(abi.encodeWithSelector(IMoshiBorderRegistry.ErrUnknownBorder.selector, (123)));

        IMoshiBorderRegistry(proxy).updateBorder(123, newConfig);
    }

    function test_upgradeToAndCall_NonOwnerCannotUpgrade() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));

        MoshiBorderRegistry(proxy).upgradeToAndCall(address(1), "");
    }

    function test_upgradeToAndCall_OwnerCanUpgrade() public {
        address proxy = address(new ERC1967Proxy(address(registry), proxyInit));
        vm.prank(MoshiBorderRegistry(proxy).owner());

        MoshiBorderRegistry(proxy).upgradeToAndCall(address(new Proxiable()), "");
    }
}
