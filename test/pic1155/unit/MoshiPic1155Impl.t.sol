// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiBorderConfig} from "../../../src/entities/MoshiBorderConfig.sol";

import {MoshiContractConfig} from "../../../src/entities/MoshiContractConfig.sol";
import {MoshiPicConfig} from "../../../src/entities/MoshiPicConfig.sol";
import {MoshiSharedSettings} from "../../../src/entities/MoshiSharedSettings.sol";
import {IMoshiBorderRegistry} from "../../../src/interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../../../src/interfaces/IMoshiMinter.sol";
import {IMoshiPic1155} from "../../../src/interfaces/IMoshiPic1155.sol";
import {MoshiPic1155Impl} from "../../../src/pic1155/MoshiPic1155Impl.sol";

import {MoshiPic1155Proxy} from "../../../src/pic1155/MoshiPic1155Proxy.sol";
import {MoshiBorderRegistry} from "../../../src/registry/MoshiBorderRegistry.sol";
import {MoshiFeeSplit} from "../../../src/splits/MoshiFeeSplit.sol";
import {MoshiBorderRegistryFixtures} from "../../fixtures/MoshiBorderRegistryFixtures.sol";
import {MoshiPic1155Fixtures} from "../../fixtures/MoshiPic1155Fixtures.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract MoshiPic1155ImplTest is Test {
    address testUser = makeAddr("user");

    function setUp() public {
        vm.deal(testUser, 100 ether);
        vm.deal(MoshiPic1155Fixtures.testMinter, 100 ether);
        vm.deal(MoshiPic1155Fixtures.testOwner, 100 ether);
    }

    function test_constructor_CannotInitWithZeroAddressMoshiWallet() public {
        MoshiSharedSettings memory settings = MoshiPic1155Fixtures.defaultSharedSettings();
        settings.moshiWallet = payable(address(0));

        vm.expectRevert();
        new MoshiPic1155Impl(settings);
    }

    function test_constructor_CannotInitWithZeroAddressBorderRegistry() public {
        MoshiSharedSettings memory settings = MoshiPic1155Fixtures.defaultSharedSettings();
        settings.borderRegistry = IMoshiBorderRegistry(address(0));

        vm.expectRevert();
        new MoshiPic1155Impl(settings);
    }

    function test_constructor_CannotInitWithZeroAddressMinter() public {
        MoshiSharedSettings memory settings = MoshiPic1155Fixtures.defaultSharedSettings();
        settings.minter = IMoshiMinter(address(0));

        vm.expectRevert();
        new MoshiPic1155Impl(settings);
    }

    function test_constructor_CannotInitWithZeroStartPrefixTokenId() public {
        MoshiSharedSettings memory settings = MoshiPic1155Fixtures.defaultSharedSettings();
        settings.startPrefixedTokenId = 0;

        vm.expectRevert();
        new MoshiPic1155Impl(settings);
    }

    function test_initialize_CannotReinitialize() public {
        MoshiPic1155Impl pic = new MoshiPic1155Impl(MoshiPic1155Fixtures.defaultSharedSettings());

        vm.expectRevert(Initializable.InvalidInitialization.selector);

        pic.initialize(MoshiPic1155Fixtures.defaultContractConfig());
    }

    function test_initialize_CannotInitializeWithZeroAddressOwner() public {
        vm.expectRevert();
        vm.expectRevert();

        new BeaconProxy(
            address(MoshiPic1155Fixtures.createPic1155Beacon()),
            abi.encodeCall(
                MoshiPic1155Impl.initialize,
                (MoshiContractConfig({owner: address(0), mintPrice: MoshiPic1155Fixtures.testMintPrice}))
            )
        );
    }

    function test_initialize_SetsNextTokenIdToExpectedValue() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        vm.assertEq(MoshiPic1155Fixtures.testStartPrefixedTokenId, moshiPic.nextTokenId());
    }

    function test_mintAdmin_MinterCanMint() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mintAdmin_OwnerCannotMint() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testOwner, 1 ether);

        vm.expectRevert();

        moshiPic.mintAdmin(MoshiPic1155Fixtures.testOwner, 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mintAdmin_NonMinterCannotMint() public {
        address user = makeAddr("user");
        vm.startPrank(user);
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        vm.expectRevert();

        moshiPic.mintAdmin(user, 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mintAdmin_MintsExpectedTokenAndQuantity() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        uint256 tokenId = moshiPic.mintAdmin(testUser, 10, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(10, moshiPic.balanceOf(testUser, tokenId));
    }

    function test_mintAdmin_ReturnsNewTokenIdEachTime() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        startHoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        uint256 tokenId = moshiPic.mintAdmin(testUser, 1, MoshiPic1155Fixtures.defaultPicConfig());

        uint256 nextTokenId = moshiPic.mintAdmin(testUser, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(1, moshiPic.balanceOf(testUser, tokenId));
        assertEq(1, moshiPic.balanceOf(testUser, nextTokenId));
    }

    function test_mintAdmin_AssignsExpectedTokenUri() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        uint256 tokenId = moshiPic.mintAdmin(testUser, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq("https://api.moshi.cam/api/v1/metadata/some-uid.json", moshiPic.uri(tokenId));
    }

    function test_mintAdmin_AssignsExpectedBorderId() public {
        IMoshiBorderRegistry borderRegistry = MoshiBorderRegistryFixtures.createBorderRegistry();
        MoshiBorderConfig memory newConfig = MoshiBorderConfig({creator: address(1337), creatorFeeBps: 1337});
        uint256 borderId = borderRegistry.addBorder(newConfig);
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155(
            MoshiPic1155Fixtures.Options({
                registry: borderRegistry,
                minter: IMoshiMinter(MoshiPic1155Fixtures.testMinter),
                newOwner: testUser
            })
        );
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        uint256 tokenId = moshiPic.mintAdmin(testUser, 1, MoshiPicConfig(borderId, "someUid"));

        assertEq(borderId, moshiPic.borderId(tokenId));
    }

    function test_mintAdmin_CannotMintToZeroAddress() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        vm.expectRevert();

        moshiPic.mintAdmin(address(0), 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mintAdmin_FailsIfTokenUidIsEmpty() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(IMoshiPic1155.InvalidPicConfiguration.selector, "tokenUid is empty"));

        moshiPic.mintAdmin(testUser, 1, MoshiPicConfig(0, ""));
    }

    function test_mintAdmin_FailsIfBorderDoesNotExist() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.prank(MoshiPic1155Fixtures.testMinter);

        vm.expectRevert(abi.encodeWithSelector(IMoshiBorderRegistry.ErrUnknownBorder.selector, 1337));

        moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 1, MoshiPicConfig(1337, "someUid"));
    }

    function test_mintAdmin_IncrementsNextTokenId() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        uint256 expectedTokenId = moshiPic.nextTokenId() + 1;
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(expectedTokenId, MoshiPic1155Impl(address(moshiPic)).nextTokenId());
    }

    function test_mintAdmin_TransfersExpectedEther() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        uint256 moshiBalanceBefore = MoshiPic1155Fixtures.testMoshiWallet.balance;
        uint256 picBalanceBefore = address(moshiPic).balance;
        uint256 borderBalanceBefore = MoshiBorderRegistryFixtures.testBorderCreator.balance;

        moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(moshiBalanceBefore, MoshiPic1155Fixtures.testMoshiWallet.balance, "balance should not change");
        assertEq(picBalanceBefore, address(moshiPic).balance, "balance should not change");
        assertEq(
            borderBalanceBefore, MoshiBorderRegistryFixtures.testBorderCreator.balance, "balance should not change"
        );
    }

    function test_mintAdmin_CannotMintZeroQuantity() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        vm.expectRevert();

        moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 0, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mintAdmin_EmitsCreateEvent() public {
        startHoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        MoshiPicConfig memory config = MoshiPic1155Fixtures.defaultPicConfig();

        vm.expectEmit(true, true, true, false);
        emit IMoshiPic1155.MoshiCreated(MoshiPic1155Fixtures.testMinter, moshiPic.nextTokenId(), config.borderId, 1);

        moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 1, config);
    }

    function test_mint_MinterCanMint() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.prank(MoshiPic1155Fixtures.testMinter);

        moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mint_OwnerCannotMint() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testOwner, 1 ether);

        vm.expectRevert();

        moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testOwner, 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mint_NonMinterCannotMint() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(testUser, 1 ether);

        vm.expectRevert();

        moshiPic.mint{value: MoshiPic1155Fixtures.testMintPrice}(testUser, 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mint_CannotMintZeroQuantity() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        vm.expectRevert();

        moshiPic.mint(MoshiPic1155Fixtures.testMinter, 0, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mint_MintsExpectedTokenAndQuantity() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        uint256 tokenId = moshiPic.mint{value: MoshiPic1155Fixtures.testMintPrice * 10}(
            testUser, 10, MoshiPic1155Fixtures.defaultPicConfig()
        );

        assertEq(10, moshiPic.balanceOf(testUser, MoshiPic1155Fixtures.testStartPrefixedTokenId));
        assertEq(MoshiPic1155Fixtures.testStartPrefixedTokenId, tokenId);
        assertEq(10, moshiPic.balanceOf(testUser, tokenId));
    }

    function test_mint_ReturnsNewTokenIdEachTime() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        startHoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        uint256 tokenId = moshiPic.mint{value: 0.1 ether}(testUser, 1, MoshiPic1155Fixtures.defaultPicConfig());

        uint256 nextTokenId = moshiPic.mint{value: 0.1 ether}(testUser, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(1, moshiPic.balanceOf(testUser, tokenId));
        assertEq(1, moshiPic.balanceOf(testUser, nextTokenId));
        assertEq(tokenId + 1, nextTokenId);
    }

    function test_mint_AssignsExpectedTokenUri() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.prank(MoshiPic1155Fixtures.testMinter);

        uint256 tokenId =
            moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq("https://api.moshi.cam/api/v1/metadata/some-uid.json", moshiPic.uri(tokenId));
    }

    function test_mint_AssignsExpectedBorderId() public {
        IMoshiBorderRegistry borderRegistry = MoshiBorderRegistryFixtures.createBorderRegistry();
        MoshiBorderConfig memory newConfig = MoshiBorderConfig({creator: address(1337), creatorFeeBps: 1337});
        uint256 borderId = borderRegistry.addBorder(newConfig);
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155(
            MoshiPic1155Fixtures.Options({
                registry: borderRegistry,
                minter: IMoshiMinter(MoshiPic1155Fixtures.testMinter),
                newOwner: testUser
            })
        );
        vm.prank(MoshiPic1155Fixtures.testMinter);

        uint256 tokenId =
            moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPicConfig(borderId, "some-uid"));

        assertEq(borderId, moshiPic.borderId(tokenId));
    }

    function test_mint_CannotMintToZeroAddress() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InvalidReceiver.selector, address(0)));

        moshiPic.mint{value: 0.1 ether}(address(0), 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mint_FailsIfInsufficientEtherSent() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        vm.expectRevert();

        moshiPic.mint(testUser, 1, MoshiPic1155Fixtures.defaultPicConfig());
    }

    function test_mint_FailsIfTokenUidIsEmpty() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(IMoshiPic1155.InvalidPicConfiguration.selector, "tokenUid is empty"));

        moshiPic.mint{value: 0.1 ether}(testUser, 1, MoshiPicConfig(0, ""));
    }

    function test_mint_FailsIfBorderDoesNotExist() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(IMoshiBorderRegistry.ErrUnknownBorder.selector, 1337));

        moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPicConfig(1337, "someUid"));
    }

    function test_mint_IncrementsNextTokenId() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(0x6d7368 * 10 ** 9 + 1, IMoshiPic1155(address(moshiPic)).nextTokenId());
    }

    function test_mint_TransfersExpectedEther() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        uint256 expectedMoshiSplit = (MoshiFeeSplit.ONE_HUNDRED_PCT_BPS - MoshiBorderRegistryFixtures.testCreatorFeeBps);

        moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(0, address(moshiPic).balance, "pic contract should not have balance from paid mint");
        assertNotEq(0, MoshiPic1155Fixtures.testMoshiWallet.balance, "moshi should have been paid");
        assertNotEq(0, MoshiBorderRegistryFixtures.testBorderCreator.balance, "border creator should have been paid");
        assertEq(
            (0.1 ether * expectedMoshiSplit) / MoshiFeeSplit.ONE_HUNDRED_PCT_BPS,
            MoshiPic1155Fixtures.testMoshiWallet.balance
        );
        assertEq(
            (0.1 ether * uint256(MoshiBorderRegistryFixtures.testCreatorFeeBps)) / MoshiFeeSplit.ONE_HUNDRED_PCT_BPS,
            MoshiBorderRegistryFixtures.testBorderCreator.balance
        );
    }

    function test_mint_EmitsCreateEvent() public {
        startHoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        MoshiPicConfig memory config = MoshiPic1155Fixtures.defaultPicConfig();

        vm.expectEmit(true, true, true, false);
        emit IMoshiPic1155.MoshiCreated(MoshiPic1155Fixtures.testMinter, moshiPic.nextTokenId(), config.borderId, 1);

        moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, config);
    }

    function test_collect_DoesNotChangeNextTokenId() public {
        vm.prank(MoshiPic1155Fixtures.testMinter);
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.prank(MoshiPic1155Fixtures.testMinter);
        uint256 tokenId =
            moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());
        uint256 startingTokenId = IMoshiPic1155(address(moshiPic)).nextTokenId();
        vm.stopPrank();
        startHoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        moshiPic.collect{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, tokenId, 1);

        assertEq(startingTokenId, IMoshiPic1155(address(moshiPic)).nextTokenId());
    }

    function test_collect_RevertsWithIdBeforeStartPrefix() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.deal(address(0x123), 1 ether);
        hoax(address(0x123), 1 ether);
        uint256 tokenId = MoshiPic1155Fixtures.testStartPrefixedTokenId - 1;

        vm.expectRevert(abi.encodeWithSelector(IMoshiPic1155.TokenIdDoesNotExist.selector, tokenId));

        moshiPic.collect{value: 0.1 ether}(address(1), tokenId, 1);
    }

    function test_collect_RevertsWithIdEqNextTokenId() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.deal(address(0x123), 1 ether);
        hoax(address(0x123), 1 ether);
        uint256 tokenId = MoshiPic1155Fixtures.testStartPrefixedTokenId;

        vm.expectRevert(abi.encodeWithSelector(IMoshiPic1155.TokenIdDoesNotExist.selector, tokenId));

        moshiPic.collect{value: 0.1 ether}(address(1), tokenId, 1);
    }

    function test_collect_RevertsWithIdAfterNextTokenId() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.deal(address(0x123), 1 ether);
        hoax(address(0x123), 1 ether);
        uint256 tokenId = MoshiPic1155Fixtures.testStartPrefixedTokenId + 1;

        vm.expectRevert(abi.encodeWithSelector(IMoshiPic1155.TokenIdDoesNotExist.selector, tokenId));

        moshiPic.collect{value: 0.1 ether}(address(1), tokenId, 1);
    }

    function test_collect_OwnerCanMint() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.prank(MoshiPic1155Fixtures.testMinter);
        uint256 tokenId =
            moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());
        hoax(MoshiPic1155Fixtures.testOwner, 1 ether);

        moshiPic.collect{value: 0.1 ether}(MoshiPic1155Fixtures.testOwner, tokenId, 1);

        assertEq(1, moshiPic.balanceOf(MoshiPic1155Fixtures.testOwner, tokenId));
    }

    function test_collect_NonOwnerCanMint() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.prank(MoshiPic1155Fixtures.testMinter);
        uint256 tokenId =
            moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());
        hoax(testUser, 1 ether);

        moshiPic.collect{value: 0.1 ether}(testUser, tokenId, 1);

        assertEq(1, moshiPic.balanceOf(testUser, tokenId));
    }

    function test_collect_FailsIfInsufficientEtherSent() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        vm.prank(MoshiPic1155Fixtures.testMinter);
        moshiPic.mint{value: MoshiPic1155Fixtures.testMintPrice}(
            MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig()
        );
        vm.prank(testUser);

        vm.expectRevert();

        moshiPic.collect(testUser, 0, 1);
    }

    function test_collect_CannotMintToZeroAddress() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        startHoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        uint256 tokenId = moshiPic.mint{value: MoshiPic1155Fixtures.testMintPrice}(
            MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig()
        );

        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InvalidReceiver.selector, address(0)));

        moshiPic.collect{value: 0.1 ether}(address(0), tokenId, 1);
    }

    function test_collect_CannotMintZeroQuantity() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        moshiPic.mint{value: MoshiPic1155Fixtures.testMintPrice}(
            MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig()
        );

        vm.expectRevert();

        moshiPic.collect(MoshiPic1155Fixtures.testMinter, 0, 0);
    }

    function test_collect_TransfersExpectedEther() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        startHoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        uint256 tokenId =
            moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());
        uint256 expectedMoshiSplit = MoshiPic1155Fixtures.testMoshiCollectFeeBps;
        uint256 expectedPicSplit =
            (MoshiFeeSplit.ONE_HUNDRED_PCT_BPS - expectedMoshiSplit - MoshiBorderRegistryFixtures.testCreatorFeeBps);

        moshiPic.collect{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, tokenId, 1);

        assertNotEq(0, address(moshiPic).balance, "pic contract should have been paid");
        assertNotEq(0, MoshiPic1155Fixtures.testMoshiWallet.balance, "moshi should have been paid");
        assertNotEq(0, MoshiBorderRegistryFixtures.testBorderCreator.balance, "border creator should have been paid");
        assertEq(
            (0.1 ether * expectedMoshiSplit) / MoshiFeeSplit.ONE_HUNDRED_PCT_BPS,
            MoshiPic1155Fixtures.testMoshiWallet.balance
        );
        assertEq((0.1 ether * expectedPicSplit) / MoshiFeeSplit.ONE_HUNDRED_PCT_BPS, address(moshiPic).balance);
        assertEq(
            (0.1 ether * uint256(MoshiBorderRegistryFixtures.testCreatorFeeBps)) / MoshiFeeSplit.ONE_HUNDRED_PCT_BPS,
            MoshiBorderRegistryFixtures.testBorderCreator.balance
        );
    }

    function test_collect_EmitsCollectEvent() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        startHoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        uint256 tokenId =
            moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        vm.expectEmit(true, true, true, false);
        emit IMoshiPic1155.MoshiCollected(MoshiPic1155Fixtures.testMinter, tokenId, moshiPic.borderId(tokenId), 1);

        moshiPic.collect{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, tokenId, 1);
    }

    function test_uri_FailsIfTokenIdDoesNotExist() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        vm.expectRevert(abi.encodeWithSelector(IMoshiPic1155.TokenIdDoesNotExist.selector, 0));

        moshiPic.uri(0);
    }

    function test_uri_ReturnsExpectedTokenUri() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);
        uint256 tokenId =
            moshiPic.mintAdmin(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        vm.assertEq("https://api.moshi.cam/api/v1/metadata/some-uid.json", moshiPic.uri(tokenId));
    }

    function test_name_ReturnsName() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        assertNotEq("", moshiPic.name());
    }

    function test_symbol_ReturnsSymbol() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        assertNotEq("", moshiPic.symbol());
    }

    function test_supportsInterface_IERC1155() public {
        bytes4 interfaceId = type(IERC1155).interfaceId;
        IMoshiPic1155 moshiPic = new MoshiPic1155Impl(MoshiPic1155Fixtures.defaultSharedSettings());

        assertTrue(moshiPic.supportsInterface(interfaceId));
    }

    function test_supportsInterface_ERC1155MetadataURI() public {
        bytes4 interfaceId = type(IERC1155MetadataURI).interfaceId;
        IMoshiPic1155 moshiPic = new MoshiPic1155Impl(MoshiPic1155Fixtures.defaultSharedSettings());

        assertTrue(moshiPic.supportsInterface(interfaceId));
    }

    function test_totalSupply_NoMintsSupplyIsZero() public {
        IMoshiPic1155 moshiPic = new MoshiPic1155Impl(MoshiPic1155Fixtures.defaultSharedSettings());

        assertEq(0, moshiPic.totalSupply());
    }

    function test_totalSupply_MintSupplyIsExpected() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(1, moshiPic.totalSupply());
    }

    function test_totalSupply_NoMintsTokenIdSupplyIsZero() public {
        IMoshiPic1155 moshiPic = new MoshiPic1155Impl(MoshiPic1155Fixtures.defaultSharedSettings());

        assertEq(0, moshiPic.totalSupply(0));
    }

    function test_totalSupply_MintTokenIdSupplyIsExpected() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();
        hoax(MoshiPic1155Fixtures.testMinter, 1 ether);

        uint256 id =
            moshiPic.mint{value: 0.1 ether}(MoshiPic1155Fixtures.testMinter, 1, MoshiPic1155Fixtures.defaultPicConfig());

        assertEq(1, moshiPic.totalSupply(id));
    }

    function test_moshiWallet_ReturnsExpectedWallet() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        assertEq(MoshiPic1155Fixtures.testMoshiWallet, moshiPic.moshiWallet());
    }

    function test_minter_ReturnsExpectedMinter() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        assertEq(MoshiPic1155Fixtures.testMinter, moshiPic.minter());
    }

    function test_mintPrice_ReturnsExpectedMintPrice() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        assertEq(MoshiPic1155Fixtures.testMintPrice, moshiPic.mintPrice());
    }

    function test_borderRegistry_ReturnsExpectedBorderRegistry() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155(
            MoshiPic1155Fixtures.Options({
                registry: IMoshiBorderRegistry(MoshiPic1155Fixtures.testRegistry),
                minter: IMoshiMinter(MoshiPic1155Fixtures.testMinter),
                newOwner: MoshiPic1155Fixtures.testOwner
            })
        );

        assertEq(MoshiPic1155Fixtures.testRegistry, moshiPic.borderRegistry());
    }

    function test_moshiFee_ReturnsExpectedMoshiFee() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        assertEq(MoshiPic1155Fixtures.testMoshiCollectFeeBps, moshiPic.moshiCollectFee());
    }

    function test_withdraw_NonOwnerCannotWithdraw() public {
        address nonOwner = makeAddr("nonOwner");
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));

        vm.prank(nonOwner);
        moshiPic.withdraw();
    }

    function test_withdraw_WithdrawsBalanceToOwner() public {
        address picCreator = makeAddr("picCreator");
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155(
            MoshiPic1155Fixtures.Options({
                registry: IMoshiBorderRegistry(MoshiPic1155Fixtures.testRegistry),
                minter: IMoshiMinter(MoshiPic1155Fixtures.testMinter),
                newOwner: picCreator
            })
        );
        vm.deal(address(moshiPic), 100 ether);
        vm.prank(picCreator);

        moshiPic.withdraw();

        assertEq(100 ether, picCreator.balance);
        assertEq(0, address(moshiPic).balance);
    }

    function test_withdraw_EmitsEvent() public {
        address picCreator = makeAddr("picCreator");
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155(
            MoshiPic1155Fixtures.Options({
                registry: IMoshiBorderRegistry(MoshiPic1155Fixtures.testRegistry),
                minter: IMoshiMinter(MoshiPic1155Fixtures.testMinter),
                newOwner: picCreator
            })
        );
        vm.deal(address(moshiPic), 100 ether);
        vm.prank(picCreator);
        vm.expectEmit(true, false, false, true);
        emit IMoshiPic1155.Withdraw(picCreator, 100 ether);

        moshiPic.withdraw();
    }

    function test_usingPrefixedScheme_UsesPrefixedScheme() public {
        IMoshiPic1155 moshiPic = MoshiPic1155Fixtures.createPic1155();

        assertTrue(MoshiPic1155Impl(address(moshiPic)).usingPrefixedScheme());
    }
}
