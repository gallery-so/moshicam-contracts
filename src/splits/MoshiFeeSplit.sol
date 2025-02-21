// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Split fees to multiple addresses
library MoshiFeeSplit {
    /// Max percentage in basis points
    uint16 constant ONE_HUNDRED_PCT_BPS = 10_000;

    // Emitted when fees are split
    event SplitFees(
        address indexed moshi,
        uint256 moshiCut,
        address indexed picCreator,
        uint256 picCreatorCut,
        address indexed borderCreator,
        uint256 borderCreatorCut
    );

    /// Raised when the total cut is greater than 100%
    error InvalidSplitCutTotal();

    /// @notice Send cut of `msg.value` to moshi and the border creator. Remaining value is left in the calling contract.
    /// @param moshi The address to send the moshi cut
    /// @param moshiFeeBps The moshi protocol fee in basis points
    /// @param borderCreator The address to send the border creator cut
    /// @param borderCreatorBps The border creator cut in basis points
    function split(address payable moshi, uint16 moshiFeeBps, address borderCreator, uint16 borderCreatorBps)
        internal
    {
        if (moshiFeeBps + borderCreatorBps > ONE_HUNDRED_PCT_BPS) {
            revert InvalidSplitCutTotal();
        }

        uint256 value = msg.value;
        uint256 borderCut = 0;
        uint256 moshiCut = 0;
        uint256 picCreatorCut = 0;

        if (moshi != address(0)) {
            moshiCut = (value * moshiFeeBps) / ONE_HUNDRED_PCT_BPS;
        }

        if (borderCreator != address(0)) {
            borderCut = (value * borderCreatorBps) / ONE_HUNDRED_PCT_BPS;
        }

        picCreatorCut = value - moshiCut - borderCut;

        if (moshiCut > 0) {
            (bool sentMoshi,) = moshi.call{value: moshiCut}("");
            require(sentMoshi, "failed to send cut to moshi");
        }

        if (borderCut > 0) {
            (bool sentBorder,) = borderCreator.call{value: borderCut}("");
            require(sentBorder, "failed to send cut to border creator");
        }

        emit SplitFees(moshi, moshiCut, address(this), picCreatorCut, borderCreator, borderCut);
    }
}
