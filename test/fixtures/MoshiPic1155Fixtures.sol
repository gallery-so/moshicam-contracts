// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiContractConfig} from "../../src/entities/MoshiContractConfig.sol";

import {MoshiPicConfig} from "../../src/entities/MoshiPicConfig.sol";
import {MoshiSharedSettings} from "../../src/entities/MoshiSharedSettings.sol";
import {IMoshiBorderRegistry} from "../../src/interfaces/IMoshiBorderRegistry.sol";
import {IMoshiMinter} from "../../src/interfaces/IMoshiMinter.sol";
import {IMoshiPic1155} from "../../src/interfaces/IMoshiPic1155.sol";
import {MoshiPic1155Impl} from "../../src/pic1155/MoshiPic1155Impl.sol";
import {MoshiPic1155Proxy} from "../../src/pic1155/MoshiPic1155Proxy.sol";

import {MoshiBorderRegistryFixtures} from "./MoshiBorderRegistryFixtures.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

library MoshiPic1155Fixtures {
    address payable constant testMoshiWallet = payable(address(0x1234));
    address constant testMinter = address(0x5678);
    address constant testOwner = address(0xDEF0);
    address constant testRegistry = address(0x4567);
    uint16 constant testMoshiCollectFeeBps = 2000;
    uint256 constant testMintPrice = 0.001 ether;
    uint256 constant testStartPrefixedTokenId = 0x6d7368 * 10 ** 9;

    struct Options {
        IMoshiBorderRegistry registry;
        IMoshiMinter minter;
        address newOwner;
    }

    function defaultPicConfig() internal pure returns (MoshiPicConfig memory) {
        return MoshiPicConfig({borderId: 0, tokenUid: "some-uid"});
    }

    function defaultContractConfig() internal pure returns (MoshiContractConfig memory) {
        return MoshiContractConfig({owner: testOwner, mintPrice: testMintPrice});
    }

    function defaultSharedSettings() internal pure returns (MoshiSharedSettings memory) {
        return MoshiSharedSettings({
            moshiWallet: testMoshiWallet,
            borderRegistry: IMoshiBorderRegistry(testRegistry),
            minter: IMoshiMinter(testMinter),
            moshiCollectFeeBps: testMoshiCollectFeeBps,
            startPrefixedTokenId: testStartPrefixedTokenId
        });
    }

    function createPic1155() internal returns (IMoshiPic1155 pic1155) {
        return createPic1155(
            Options({
                registry: MoshiBorderRegistryFixtures.createBorderRegistry(),
                minter: IMoshiMinter(testMinter),
                newOwner: testOwner
            })
        );
    }

    function createPic1155(Options memory options) internal returns (IMoshiPic1155 pic1155) {
        IMoshiPic1155 beacon = _createPic1155Beacon(options);
        MoshiContractConfig memory contractConfig = defaultContractConfig();
        contractConfig.owner = options.newOwner;
        pic1155 = IMoshiPic1155(
            address(new BeaconProxy(address(beacon), abi.encodeCall(IMoshiPic1155.initialize, (contractConfig))))
        );
    }

    function createPic1155Beacon() internal returns (IMoshiPic1155 pic1155) {
        return _createPic1155Beacon(
            Options({
                registry: MoshiBorderRegistryFixtures.createBorderRegistry(),
                minter: IMoshiMinter(testMinter),
                newOwner: testOwner
            })
        );
    }

    function createPic1155Beacon(Options memory options) internal returns (IMoshiPic1155 pic1155) {
        return _createPic1155Beacon(options);
    }

    function _createPic1155Beacon(Options memory options) private returns (IMoshiPic1155 pic1155) {
        MoshiPic1155Impl moshiPic = new MoshiPic1155Impl(
            MoshiSharedSettings({
                moshiWallet: testMoshiWallet,
                borderRegistry: options.registry,
                minter: options.minter,
                moshiCollectFeeBps: testMoshiCollectFeeBps,
                startPrefixedTokenId: testStartPrefixedTokenId
            })
        );
        pic1155 = IMoshiPic1155(address(new UpgradeableBeacon(address(moshiPic), options.newOwner)));
    }
}
