## Contracts

This project is built using Foundry. For more information, visit the docs [here](https://book.getfoundry.sh/)

# Disclaimer

The provided Solidity contracts are intended solely for educational purposes and are
not warranted for any specific use. They have not been audited and may contain vulnerabilities, hence should
not be deployed in production environments. Users are advised to seek professional review and conduct a
comprehensive security audit before any real-world application to mitigate risks of financial loss or other
consequences. The author(s) disclaim all liability for any damages arising from the use of these contracts.
Use at your own risk, acknowledging the inherent risks of smart contract technology on the blockchain.

# Contents

- [Introduction](#introduction)
  - [Contracts](#contracts)
    - [Entities](#entities)
    - [Interfaces](#interfaces)
    - [Minter](#minter)
    - [Pic1155](#pic1155)
    - [Registry](#registry)
    - [Splits](#splits)
- [Project Layout](#project-layout)
- [Usage](#usage)
- [Deploying your own contract](#deploying-your-own-contract)
- [Deploying to local node](#deploy-to-local-node)
- [Contributing](#contributing)

## Introduction

### Contracts

#### Entities
Common structs used by many contracts.
| Name | Description |
|--|--|
|`MoshiBorderConfig.sol`| Defines a Moshi Border configuration  |
|`MoshiContractConfig.sol`| Defines a `MoshiPic1155Impl` configuration |
|`MoshiPicConfig.sol`| Defines a new `MoshiPic1155Impl` token |
|`MoshiSharedSettings.sol`| Defines shared protocol settings |
#### Interfaces
Contains externally accessible interfaces into Moshi.
| Name | Description |
|--|--|
|`IMoshiBorderRegistry.sol`| Defines the interface of the Border Registry |
|`IMoshiMinter.sol`| Defines the interface of the Minter |
|`IMoshiPic1155.sol`| Defines the interface of a `MoshiPic1155` |
#### Minter
Main entry point contract that onboards new accounts into Moshi.
| Name | Description |
|--|--|
|`MoshiMinterImpl.sol`| Contract that creates and mints new pics |
|`MoshiMinterProxy.sol`| Proxy to the minter implementation |
#### Pic1155
Contract that allows a user to mint and collect new ERC1155s.
| Name | Description |
|--|--|
|`MoshiPic1155Beacon.sol`| Updradeable beacon contract |
|`MoshiPic1155Impl.sol`| Implementation contract that allows for minting and collecting of new pics  |
|`MoshiPic1155Proxy.sol`| Proxy contract that may be updated to point to new pic implementations |
|`MoshiPic1155Storage.sol`| Defines the storage layout of `MoshiPic1155Impl` |
#### Registry
Contract that manages border configurations.
| Name | Description |
|--|--|
|`MoshiBorderRegistry.sol`| Contract that stores border data |
|`MoshiBorderRegistryProxy.sol`| Proxy to the border registry implementation |
#### Splits
Collection of contracts and libraries that handle protocol fee splits.
| Name | Description |
|--|--|
|`MoshiFeeSplit.sol`| Library for handling fee splits |

### Project Layout

```
.
├── foundry.toml
├── script
│   └── contracts
│   │   └── DeployerBase.sol
│   │   └── Logger.sol
│   │   └── MoshiDeployer.sol
│   └── smoke
│   │   └── SmokeTest.sol
│   └── DeployMoshi.s.sol
├── src
│   └── entities
│   │   └── MoshiBorderConfig.sol
│   │   └── MoshiContractConfig.sol
│   │   └── MoshiPicConfig.sol
│   │   └── MoshiSharedSettings.sol
│   └── interfaces
│   │   └── IMoshiBorderRegistry.sol
│   │   └── IMoshiMinter.sol
│   │   └── IMoshiPic1155.sol
│   └── minter
│   │   └── MoshiMinterImpl.sol
│   │   └── MoshiMinterProxy.sol
│   └── pic1155
│   │   └── MoshiPic1155Beacon.sol
│   │   └── MoshiPic1155Impl.sol
│   │   └── MoshiPic1155Proxy.sol
│   │   └── MoshiPic1155Storage.sol
│   └── registry
│   │   └── MoshiBorderRegistry.sol
│   │   └── MoshiBorderRegistryProxy.sol
│   └── splits
│   │   └── MoshiFeeSplit.sol
└── test
│   └── contracts
│   │   └── MoshiPic1155V2.sol
│   └── fixtures
│   │   └── MoshiBorderRegistryFixtures.sol
│   │   └── MoshiMinterFixtures.sol
│   │   └── MoshiPic1155Fixtures.sol
│   └── minter
│   │   └── MoshiMinterImpl.t.sol
│   └── pic1155
│   │   └── upgrade
│   │   │   └── MoshiPic1155Upgrade.t.sol
│   │   └── unit
│   │   │   └── MoshiPic1155.t.sol
│   └── registry
│   │   └── MoshiBorderRegistry.t.sol
│   └── splits
│   │   └── MoshiFeeSplit.t.sol
```

- You can configure Foundry's behavior using foundry.toml.
- The default directory for contracts is src/.
- The default directory for tests is test/
- The default directory for writing scripts is script/

## Usage

### Installation

Install foundry using

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Follow the instructions of foundryup to completely setup foundry

### Install dependencies

```shell
forge install
```

### Build

```shell
forge build
```

### Test

```shell
make test
```

### Coverage

You will need to install [genhtml](https://github.com/linux-test-project/lcov) to generate html reports (`brew install lcov` for osx).

```shell
make coverage
```

### Format

```shell
make format
```

### Deploy and verify contracts on Base Sepolia

Open `.env` file.

`PRIVATE_KEY` is your private wallet key. Make sure to prefix it by "0x" to convert to a hex string.

`BLOCK_EXPLORER_API_KEY` is your API Key from [basescan.org](https://docs.basescan.org/getting-started) for Base Sepolia

```bash
source .env

forge script script/YOUR_SCRIPT.s.sol --broadcast --verify --rpc-url base_sepolia
```

Forge runs your solidity script. In that script it tries to broadcast the transaction. It writes it back into the broadcast folder in a `run-latest.json` file.

### ABI

To extract the `abi` of your contract, you can go to `out/YOUR_CONTRACT.sol/YOUR_CONTRACT.json` and copy the value corresponding to the `abi` key

## Deploying your own contract

1. To deploy your own contract create a new `.sol` file inside the `contracts/src` folder.
2. Format and build your contracts using `forge fmt` and `forge build` respectively.
3. Write some tests by creating a test file inside `contracts/test` folder. Run the test using `forge test`
4. Write a deployment script inside `contracts/script`.
5. Create a `.env` file using the `.env.example` file provided in your contracts folder and add your private key. Make sure to add a `0x` in front of your key to convert it to a hex string.
6. Deploy your contract using the following commands:

   ```bash
   source .env

   forge script script/YOUR_SCRIPT.s.sol:YOUR_SCRIPT --broadcast --rpc-url base_sepolia
   ```

   Note: To deploy on a different network, simply add the specific RPC endpoint within the `[rpc_endpoints]` section found in the `foundry.toml` file.
   <br/>

7. To extract the `abi` of your contract, you can go to `out/YOUR_CONTRACT.sol/YOUR_CONTRACT.json` and copy the value corresponding to the `abi` key

## Deploy to local node

Initially, building on a local node can offer numerous benefits, including:

- The ability to add debug statements.
- The capability to fork a chain at a particular block, enabling the detection of reasons behind specific behaviors.
- The absence of the need for testnet/mainnet funds.
- Faster testing, as only your node is responsible for consensus.

You can deploy your contracts to local node for faster testing as follows:

```bash
make local-node
```

To deploy the contract:

- Make sure to delete the following lines from `foundry.toml` because locally we dont have a block explorer

  ```
  [etherscan]
  "${NETWORK}"={key="${BLOCK_EXPLORER_API_KEY}"}
  ```

- Create a `.env` file using the `.env.example` file provided in your contracts folder and add one the private keys printed on your terminal when you ran `make local-node`. Also update the `RPC_URL` to `http://127.0.0.1:8545`, this will make sure your contracts are deployed locally

- Deploy the sample contract using:
  ```
  source .env
  forge script script/YOUR_SCRIPT.s.sol --broadcast --rpc-url ${RPC_URL}
  ```

You can observe that the console2 library facilitates the addition of console logs in the contract, which would not have been possible if you were deploying to a testnet or mainnet.

## Contributing

If you would like to contribute to contracts folder, follow the given steps for setup

### Installation

Install foundry using

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Follow the instructions of foundryup to completely setup foundry

### Install dependencies

Run the following commands inside the contracts folder:

```shell
forge install
forge build
```

You should be good to go :) Thank you for the support ❤️
