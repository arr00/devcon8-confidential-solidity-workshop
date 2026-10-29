# Workshop commands. Each runs the forge command below it.
.PHONY: ready test attacks

# Installs dependencies, compiles (downloading solc the first time), then encrypts and decrypts one value.
ready:
	forge soldeer install
	forge test --mc ReadyTest
	@echo "Ready for the workshop."

# The tests for deposit.
test:
	forge test --mc VaultTest

# Both attacks against your vault.
attacks:
	forge test --mc AttacksTest
