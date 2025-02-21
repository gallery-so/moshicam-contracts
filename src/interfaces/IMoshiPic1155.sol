// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MoshiContractConfig} from "../entities/MoshiContractConfig.sol";
import {MoshiPicConfig} from "../entities/MoshiPicConfig.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMoshiPic1155 is IERC165, IERC1155, IERC1155MetadataURI {
    /// Emitted when balance is withdrawn from the contract
    event Withdraw(address indexed to, uint256 amount);
    // Emitted when a new moshi is minted
    event MoshiCreated(address indexed to, uint256 indexed id, uint256 indexed borderId, uint256 quantity);
    // Emitted when a moshi is collected
    event MoshiCollected(address indexed to, uint256 indexed id, uint256 indexed borderId, uint256 quantity);

    // Raised when accessing a token that does not exist
    error TokenIdDoesNotExist(uint256 id);
    // Raised when the new pic configuration is invalid
    error InvalidPicConfiguration(string message);

    function initialize(MoshiContractConfig calldata config) external;

    /// @notice Return the owner of the contract
    function owner() external view returns (address);

    /// @notice Mint new tokens
    /// @dev Requires minter
    /// @param to The address to mint to
    /// @param quantity The quantity to transfer
    /// @param config The configuration of the token
    function mintAdmin(address to, uint256 quantity, MoshiPicConfig calldata config) external returns (uint256);

    /// @notice Mint new tokens
    /// @dev Requires owner or minter
    /// @param to The address to mint to
    /// @param quantity The quantity to transfer
    /// @param config The configuration of the token
    function mint(address to, uint256 quantity, MoshiPicConfig calldata config) external payable returns (uint256);

    /// @notice Mint an existing token
    /// @param to The address to mint to
    /// @param id The id of the token to mint
    /// @param quantity The amount to mint
    function collect(address to, uint256 id, uint256 quantity) external payable;

    /// @notice Return the border id for a token
    /// @param id The id of the token
    function borderId(uint256 id) external view returns (uint256);

    /// @notice Return the name of the token
    function name() external view returns (string memory);

    /// @notice Return the symbol of the token
    function symbol() external view returns (string memory);

    /// @notice Return the total supply of a token
    /// @param id The id of the token
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Return the total supply of all tokens
    function totalSupply() external view returns (uint256);

    /// @notice Return a uri for a token. Requires token to exists.
    /// @param id The id of the token
    function uri(uint256 id) external view returns (string memory);

    /// @notice Return the next token id
    function nextTokenId() external view returns (uint256);

    /// @notice Return the Moshi protocol wallet
    function moshiWallet() external view returns (address);

    /// @notice Return the border registry
    function borderRegistry() external view returns (address);

    /// @notice Return the minter
    function minter() external view returns (address);

    /// @notice Return the mint price
    function mintPrice() external view returns (uint256);

    /// @notice Return the moshi fee
    function moshiCollectFee() external view returns (uint16);

    /// @notice Withdraw balance from the contract
    function withdraw() external;
}
