#!/usr/bin/make
.PHONY: slither.md coverage.txt

LOCAL              := local
TESTNET            := testnet
MAINNET            := mainnet
FORGE              := forge
ANVIL              := anvil
SLITHER            := slither
DEPLOY_CMD         = $(FORGE) script DeployMoshi
ADD_BORDER_CMD     = $(FORGE) script AddBorder
PIC_UPGRADE_CMD    = $(FORGE) script UpgradeMoshiPic
MINTER_UPGRADE_CMD = $(FORGE) script UpgradeMinter
BASE_FLAGS         = --rpc-url $(ENV) --broadcast

%-$(LOCAL)     : ENV          := local
%-$(TESTNET)   : ENV          := base_sepolia
%-$(MAINNET)   : ENV          := base
%-$(LOCAL)     : DEPLOY_FLAGS = $(BASE_FLAGS)
%-$(TESTNET)   : DEPLOY_FLAGS = $(BASE_FLAGS) --verify
%-$(MAINNET)   : DEPLOY_FLAGS = $(BASE_FLAGS) --verify

local-node:
	$(ANVIL) --chain-id 31337 --port 8545

clean:
	$(FORGE) clean

deploy-%: clean
	$(DEPLOY_CMD) $(DEPLOY_FLAGS)

picupgrade-%: clean
	$(PIC_UPGRADE_CMD) $(DEPLOY_FLAGS)

minterupgrade-%: clean
	$(MINTER_UPGRADE_CMD) $(DEPLOY_FLAGS)

addborder-%:
	$(ADD_BORDER_CMD) $(DEPLOY_FLAGS)

format:
	$(FORGE) fmt

build:
	$(FORGE) build

test: clean
	$(FORGE) test --gas-report -vvv --detailed --summary

coverage.txt: clean
	$(FORGE) coverage --report summary --report debug > coverage.txt

snapshot: clean
	$(FORGE) snapshot

slither.md:
	$(SLITHER) --filter-paths=lib/ --checklist . > slither.md
