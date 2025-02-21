// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/// @title Script logging utils
abstract contract Logger is Script {
    string private constant _green = "\x1b[32m";
    string private constant _reset = "\x1b[0m";

    /// @dev Logs `msg_` to console
    /// @param msg_ The message to log
    function consoleLog(string memory msg_) internal pure {
        // solhint-disable-next-line no-console
        console2.log(msg_);
    }

    /// @dev Formats `addr` for logging
    function emphasize(address addr) internal view returns (string memory) {
        string memory label = vm.getLabel(addr);
        return string.concat(label, "@", _green, vm.toString(addr), _reset);
    }
}
