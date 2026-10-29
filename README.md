# Encrypted, Not Anonymous

A hands-on introduction to confidential Solidity, from OpenZeppelin's workshop at Devcon 8. You write a vault for confidential (ERC-7984) tokens, then attack it.

## Before the workshop

Please set up before you arrive. The first run downloads the dependencies and the Solidity compiler, which may not finish on conference wifi.

You need git, make and [Foundry](https://getfoundry.sh). To install or update Foundry:

```sh
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Then:

```sh
git clone https://github.com/arr00/devcon8-confidential-solidity-workshop
cd devcon8-confidential-solidity-workshop
make ready
```

If it prints `Ready for the workshop.`, you're set.

On Windows, use WSL or the Codespace.

## During the workshop

### Build the vault

Open `src/ConfidentialVault.sol`. `withdraw` is already written. You write `deposit`.

```sh
make test
```

The three tests fail until `deposit` works. If you're stuck, commit or stash your work, then switch to a working `deposit`:

```sh
git switch checkpoint
```

Don't run `git stash pop` on `checkpoint`: your `deposit` and the checkpoint's would conflict.

### Attack your vault

```sh
make attacks
```

This runs two attacks against your vault. Each test is named for what it protects, so green means the attack was blocked and red means Mallory won.

- **Attack 1** is ready to run.
- **Attack 2** has one blank in `test/Attacks.t.sol`: which handle should EvilToken return?

Change your `deposit` and run both attacks after every change. If both are blocked from the start, commit or stash, then `git switch checkpoint` and attack that version instead.

Finished early? Find other handles that fill attack 2's blank.

## Commands

| Command | Runs | What it does |
|---|---|---|
| `make ready` | `forge soldeer install`, then `forge test --mc ReadyTest` | Installs dependencies, compiles, then encrypts and decrypts one value |
| `make test` | `forge test --mc VaultTest` | Runs the tests for `deposit` |
| `make attacks` | `forge test --mc AttacksTest` | Runs both attacks against your vault |

## Troubleshooting

- **`forge: command not found`:** open a new terminal after installing Foundry, or run `foundryup` again.
- **Errors about unknown config keys or cheatcodes:** your Foundry is too old. Run `foundryup`. The workshop was tested with Foundry 1.8.6.
- **`make ready` stops while downloading:** run it again on a better connection.
- **Anything else:** use the Codespace. It runs the same setup in the cloud.

## How the tests run

The tests use [forge-fhevm](https://github.com/zama-ai/forge-fhevm), which deploys the FHEVM host contracts inside Foundry's test EVM and computes on cleartext. Contracts, handles and the access control list (ACL) work as they do on a real network, so the tests check your logic. Gas costs and privacy are different on a real network.

The helpers in `test/Helpers.sol` decrypt with user decryption, which checks the ACL the way a real network does. forge-fhevm's `decrypt()` skips the ACL, so reading a value with it proves nothing about an attack.

Versions: OpenZeppelin Confidential Contracts 0.5.3, `@fhevm/solidity` 0.11.1, and the FHEVM v0.11 host contracts vendored in forge-fhevm.

## After the workshop

- [OpenZeppelin Confidential Contracts](https://docs.openzeppelin.com/confidential-contracts)
- [Confidential Contracts Foundry Template](https://github.com/arr00/confidential-contracts-foundry-template)
- [OpenZeppelin Wizard for confidential contracts](https://wizard.openzeppelin.com/confidential)
- [Zama Protocol documentation](https://docs.zama.ai/protocol)
