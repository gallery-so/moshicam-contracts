// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiFeeSplit} from "../../src/splits/MoshiFeeSplit.sol";
import "forge-std/Test.sol";

contract Pic155Stub {
    function split(
        address payable moshiWallet,
        uint16 moshProtocolFeeBps,
        address borderCreatorWallet,
        uint16 borderCreatorBps
    ) public payable {
        MoshiFeeSplit.split(moshiWallet, moshProtocolFeeBps, borderCreatorWallet, borderCreatorBps);
    }
}

contract MoshiFeeSplitTest is Test {
    address moshiWallet = makeAddr("moshiWallet");
    address creatorWallet = makeAddr("creatorWallet");
    address borderCreatorWallet = makeAddr("borderCreatorWallet");
    address withdrawFactory = makeAddr("withdrawFactory");

    function test_split_RevertIfInvalidSplit() public {
        Pic155Stub pic = new Pic155Stub();

        vm.expectRevert(MoshiFeeSplit.InvalidSplitCutTotal.selector);

        pic.split{value: 100 ether}(payable(moshiWallet), 7000, borderCreatorWallet, 5000);
    }

    function test_split_SendsCutToMoshiWallet() public {
        Pic155Stub pic = new Pic155Stub();

        pic.split{value: 10 ether}(payable(moshiWallet), 10000, borderCreatorWallet, 0);

        assertEq(10 ether, moshiWallet.balance);
    }

    function test_split_RemainingValueInCallingContract() public {
        Pic155Stub pic = new Pic155Stub();

        pic.split{value: 10 ether}(payable(moshiWallet), 5000, borderCreatorWallet, 0);

        assertEq(5 ether, address(pic).balance);
    }

    function test_split_SendsCutToBorderCreatorWallet() public {
        Pic155Stub pic = new Pic155Stub();

        pic.split{value: 10 ether}(payable(moshiWallet), 0, borderCreatorWallet, 5000);

        assertEq(5 ether, borderCreatorWallet.balance);
    }

    function test_split_EmitsEvent() public {
        Pic155Stub pic = new Pic155Stub();

        vm.expectEmit(true, true, true, true);
        emit MoshiFeeSplit.SplitFees(moshiWallet, 2 ether, address(pic), 5 ether, borderCreatorWallet, 3 ether);

        pic.split{value: 10 ether}(payable(moshiWallet), 2000, borderCreatorWallet, 3000);
    }

    function test_split_NoValueSplit() public {
        Pic155Stub pic = new Pic155Stub();
        vm.expectEmit(true, true, true, true);
        emit MoshiFeeSplit.SplitFees(moshiWallet, 0 ether, address(pic), 0 ether, borderCreatorWallet, 0 ether);

        pic.split(payable(moshiWallet), 2000, borderCreatorWallet, 2000);
    }

    function test_split_ZeroAddressSplit() public {
        Pic155Stub pic = new Pic155Stub();
        vm.expectEmit(true, true, true, true);
        emit MoshiFeeSplit.SplitFees(address(0), 0 ether, address(pic), 10 ether, address(0), 0 ether);

        pic.split{value: 10 ether}(payable(address(0)), 2000, address(0), 2000);
    }
}
