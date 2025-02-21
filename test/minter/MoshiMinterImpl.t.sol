// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Proxiable} from "../../lib/openzeppelin-foundry-upgrades/test/contracts/Proxiable.sol";
import {DeployMoshi} from "../../script/DeployMoshi.s.sol";
import {MoshiBorderConfig} from "../../src/entities/MoshiBorderConfig.sol";
import {MoshiContractConfig} from "../../src/entities/MoshiContractConfig.sol";
import {MoshiPicConfig} from "../../src/entities/MoshiPicConfig.sol";
import {MoshiSharedSettings} from "../../src/entities/MoshiSharedSettings.sol";
import {IMoshiBorderRegistry} from "../../src/interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../../src/interfaces/IMoshiMinter.sol";
import {IMoshiPic1155} from "../../src/interfaces/IMoshiPic1155.sol";
import {MoshiMinterImpl} from "../../src/minter/MoshiMinterImpl.sol";
import {MoshiPic1155Impl} from "../../src/pic1155/MoshiPic1155Impl.sol";
import {MoshiPic1155Proxy} from "../../src/pic1155/MoshiPic1155Proxy.sol";
import {MoshiBorderRegistry} from "../../src/registry/MoshiBorderRegistry.sol";

import {MoshiBorderRegistryFixtures} from "../fixtures/MoshiBorderRegistryFixtures.sol";
import {MoshiMinterFixtures} from "../fixtures/MoshiMinterFixtures.sol";
import {MoshiPic1155Fixtures} from "../fixtures/MoshiPic1155Fixtures.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract MoshiMinterImplTest is Script, Test {
    IMoshiMinter minter;

    function setUp() public {
        minter = MoshiMinterFixtures.createMinter();
        IMoshiBorderRegistry registry = MoshiBorderRegistryFixtures.createBorderRegistry();
        IMoshiPic1155 pic1155 = MoshiPic1155Fixtures.createPic1155Beacon(
            MoshiPic1155Fixtures.Options({registry: registry, minter: minter, newOwner: MoshiPic1155Fixtures.testOwner})
        );
        vm.prank(MoshiMinterFixtures.testOwner);
        minter.setPicImplementation(address(pic1155));
        vm.deal(MoshiMinterFixtures.testAdminMinter, 100 ether);
    }

    function test_constructor_CannotInitialize() public {
        MoshiMinterImpl impl = new MoshiMinterImpl();

        vm.expectRevert(Initializable.InvalidInitialization.selector);

        impl.initialize(address(1), address(2));
    }

    function test_initialize_CannotInitializeWithZeroAddressOwner() public {
        vm.expectRevert();

        new ERC1967Proxy(address(minter), abi.encodeCall(MoshiMinterImpl.initialize, (address(0), address(1))));
    }

    function test_initialize_CannotInitializeWithZeroAddressAdminMinter() public {
        vm.expectRevert();

        new ERC1967Proxy(address(minter), abi.encodeCall(MoshiMinterImpl.initialize, (address(1), address(0))));
    }

    function test_mintNewPicWithFee_FailsIfInsufficientEtherSent() public {
        address alice = makeAddr("alice");
        vm.deal(alice, 1 ether);
        MoshiPicConfig memory picConfig = MoshiPicConfig({borderId: 0, tokenUid: "someUid"});
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: alice, mintPrice: 0.001 ether});
        IMoshiMinter moshiMinter_ = minter;
        hoax(alice, 1 ether);

        vm.expectRevert();

        moshiMinter_.mintNewPic(alice, 1, picConfig, contractConfig);
        vm.stopPrank();
    }

    function test_mintNewPic_MintsExpectedTokenAndQuantityToAddress() public {
        vm.startPrank(MoshiMinterFixtures.testAdminMinter);
        MoshiPicConfig memory picConfig = MoshiPicConfig({borderId: 0, tokenUid: "someUid"});
        MoshiContractConfig memory contractConfig =
            MoshiContractConfig({owner: MoshiMinterFixtures.testAdminMinter, mintPrice: 0.001 ether});
        IMoshiMinter moshiMinter_ = minter;

        (address picAddr, uint256 id) = moshiMinter_.mintNewPic{value: 0.001 ether * 10}(
            MoshiMinterFixtures.testAdminMinter, 10, picConfig, contractConfig
        );

        IMoshiPic1155 moshiPic = IMoshiPic1155(picAddr);
        assertEq(10, moshiPic.balanceOf(MoshiMinterFixtures.testAdminMinter, id));
        assertEq(MoshiMinterFixtures.testAdminMinter, IMoshiPic1155(picAddr).owner(), "expected minter to be owner");
        assertEq(MoshiPic1155Fixtures.testStartPrefixedTokenId, id);
        vm.stopPrank();
    }

    function test_mintNewPic_MsgSenderMustBeOwner() public {
        MoshiPicConfig memory picConfig = MoshiPicConfig({borderId: 0, tokenUid: "someUid"});
        MoshiContractConfig memory contractConfig =
            MoshiContractConfig({owner: makeAddr("ownerB"), mintPrice: 0.001 ether});
        address ownerA = makeAddr("ownerA");
        hoax(ownerA, 1 ether);
        IMoshiMinter moshiMinter_ = minter;

        vm.expectRevert(IMoshiMinter.SenderNotNewContractOwner.selector);

        moshiMinter_.mintNewPic(ownerA, 1, picConfig, contractConfig);
        vm.stopPrank();
    }

    function test_mintNewPicAdmin_NonAdminMinterCannotMint() public {
        MoshiPicConfig memory picConfig = MoshiPicConfig({borderId: 0, tokenUid: "someUid"});
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: address(1), mintPrice: 0.001 ether});
        address nonOwner = makeAddr("nonOwner");

        vm.expectRevert(abi.encodeWithSelector(IMoshiMinter.NotAdminMinter.selector, nonOwner));

        vm.prank(nonOwner);
        minter.mintNewPicAdmin(address(1), 1, picConfig, contractConfig);
    }

    function test_mintNewPicAdmin_MintsExpectedTokenAndQuantityToAddress() public {
        address user = makeAddr("user");
        MoshiPicConfig memory picConfig = MoshiPicConfig({borderId: 0, tokenUid: "someUid"});
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: user, mintPrice: 0.001 ether});
        vm.prank(MoshiMinterFixtures.testAdminMinter);

        (address picAddr, uint256 id) = minter.mintNewPicAdmin(user, 1, picConfig, contractConfig);

        IMoshiPic1155 moshiPic = IMoshiPic1155(picAddr);
        assertEq(1, moshiPic.balanceOf(user, id));
        assertEq(user, IMoshiPic1155(picAddr).owner(), "expected minter to be owner");
        assertEq(MoshiPic1155Fixtures.testStartPrefixedTokenId, id);
    }

    function test_mintNewPicAdmin_RevertsIfImplementationNotSet() public {
        address user = makeAddr("user");
        IMoshiMinter minterImpl = MoshiMinterFixtures.createMinter();
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: user, mintPrice: 0.001 ether});

        vm.expectRevert(IMoshiMinter.PicImplementationNotSet.selector);

        vm.prank(MoshiMinterFixtures.testAdminMinter);
        minterImpl.mintNewPicAdmin(address(1), 1, MoshiPicConfig({borderId: 0, tokenUid: "someUid"}), contractConfig);
    }

    function test_collectPic_CollectsExpectedTokenQuantityToAddress() public {
        address user = makeAddr("user");
        MoshiPicConfig memory picConfig = MoshiPicConfig({borderId: 0, tokenUid: "someUid"});
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: user, mintPrice: 0.001 ether});
        vm.prank(MoshiMinterFixtures.testAdminMinter);
        (address picAddr, uint256 id) = minter.mintNewPicAdmin(user, 1, picConfig, contractConfig);
        vm.deal(user, 1 ether);
        hoax(user, 1 ether);

        minter.collectPic{value: 0.001 ether * 4}(picAddr, user, id, 4);

        assertEq(5, IMoshiPic1155(picAddr).balanceOf(user, id));
        assertEq(5, IMoshiPic1155(picAddr).totalSupply(id));
    }

    function test_upgradeToAndCall_NonOwnerCannotUpgrade() public {
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));

        MoshiMinterImpl(address(minter)).upgradeToAndCall(address(1), "");
    }

    function test_upgradeToAndCall_OwnerCanUpgrade() public {
        vm.startPrank(minter.owner());

        MoshiMinterImpl(address(minter)).upgradeToAndCall(address(new Proxiable()), "");
    }

    function test_getOrCreatePicContract_OwnerIsOwner() public {
        address user = makeAddr("alice");
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: user, mintPrice: 0.001 ether});
        vm.prank(MoshiMinterFixtures.testAdminMinter);

        minter.mintNewPicAdmin(user, 1, MoshiPicConfig({borderId: 0, tokenUid: "someUid"}), contractConfig);

        address userContract = minter.getPicContract(user);

        assertEq(user, IMoshiPic1155(userContract).owner(), "expected user to be owner of created contract");
    }

    function test_getOrCreatePicContract_ReturnsExistingContract() public {
        address user = makeAddr("bob");
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: user, mintPrice: 0.001 ether});
        vm.startPrank(MoshiMinterFixtures.testAdminMinter);
        minter.mintNewPicAdmin(user, 1, MoshiPicConfig({borderId: 0, tokenUid: "someUid"}), contractConfig);
        address userContract = minter.getPicContract(user);
        minter.mintNewPicAdmin(user, 1, MoshiPicConfig({borderId: 0, tokenUid: "someUid"}), contractConfig);

        address otherContract = minter.getPicContract(user);
        assertEq(userContract, otherContract, "expected to return existing contract");
    }

    function test_getOrCreatePicContract_ContractCreatedEventEmits() public {
        address user = makeAddr("jim");
        vm.expectEmit(true, false, false, false);
        MoshiContractConfig memory contractConfig = MoshiContractConfig({owner: user, mintPrice: 0.001 ether});
        emit IMoshiMinter.NewPicContract(user, address(0));
        vm.prank(MoshiMinterFixtures.testAdminMinter);

        (address newContract,) =
            minter.mintNewPicAdmin(user, 1, MoshiPicConfig({borderId: 0, tokenUid: "someUid"}), contractConfig);

        assertEq(newContract, minter.getPicContract(user));
    }

    function test_setAdminMinter_NonOwnerCannotSetAdminMinter() public {
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));

        minter.setAdminMinter(nonOwner);
    }

    function test_setAdminMinter_OwnerCanSetAdminMinter() public {
        address newAdmin = makeAddr("newAdmin");
        vm.startPrank(MoshiMinterFixtures.testOwner);

        minter.setAdminMinter(newAdmin);

        assertEq(newAdmin, minter.adminMinter());
    }

    function test_setAdminMinter_EmitsEvent() public {
        address newAdmin = makeAddr("newAdmin");
        vm.startPrank(MoshiMinterFixtures.testOwner);

        vm.expectEmit(true, false, false, false);
        emit IMoshiMinter.AdminMinterChanged(newAdmin);

        minter.setAdminMinter(newAdmin);
    }

    function test_setAdminMinter_CannotSetZeroAddressAdminMinter() public {
        vm.startPrank(MoshiMinterFixtures.testOwner);

        vm.expectRevert();

        minter.setAdminMinter(address(0));
    }

    function test_setPicImplementation_NonOwnerCannotSetImplementation() public {
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));

        minter.setPicImplementation(address(1));
    }

    function test_setPicImplementation_OwnerCanSetImplementation() public {
        address newImpl = makeAddr("newImpl");
        vm.startPrank(MoshiMinterFixtures.testOwner);

        minter.setPicImplementation(newImpl);

        assertEq(newImpl, minter.picImplementation());
    }

    function test_setPicImplementation_EmitsEvent() public {
        address newImpl = makeAddr("newImpl");
        vm.startPrank(MoshiMinterFixtures.testOwner);

        vm.expectEmit(true, false, false, false);
        emit IMoshiMinter.Pic1155ImplSet(newImpl);

        minter.setPicImplementation(newImpl);
    }

    function test_setPicImplementation_CannotSetZeroAddressImplementation() public {
        vm.startPrank(MoshiMinterFixtures.testOwner);

        vm.expectRevert();

        minter.setPicImplementation(address(0));
    }
}
