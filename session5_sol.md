# OLAS Dev Academy - Session 5 Homework

The solutions on this repository are based on [trader v0.12.8](https://github.com/valory-xyz/trader/releases/tag/v0.12.8).

- Clone the repository `https://github.com/valory-xyz/trader/`
    `git clone git@github.com:valory-xyz/trader.git`
    `git checkout v0.12.8`

## Exercise 1

- Open a PR with your custom strategy on the trader repo.
- Push your strategy package to IPFS.
- Request a PR review from the maintainers (including your IPFS hash).
- Once merged, mint your strategy package on Ethereum as a Component (ComponentRegistry!)
- Share the token id of your strategy with us!

### Solution

Assuming you have created a trading strategy (see [Session V Homework](session5_sol.md)):

1. Go to the [Olas Component Registry](https://registry.olas.network/ethereum/components) and connect your wallet.

2. Click "Mint" on the upper-right corner.ç

3. Fill in:

    - Your wallet address (owner).
    - Name of your strategy.
    - Description.
    - Version.
    - Package hash. You must select `bafybei` and copy the hash from your strategy (it can be found on the file `packages/packages.json`).
    - An image URL. You can use [this sample image](https://gateway.autonolas.tech/ipfs/Qmbh9SQLbNRawh9Km3PMEDSxo77k1wib8fYZUdZkhPBiev)
    - Do not enter any dependency.

    You can find additional help on [Olas Developer Documentation - Mint packages NFTs](https://docs.autonolas.network/protocol/mint_packages_nfts/#mint-an-agent)
