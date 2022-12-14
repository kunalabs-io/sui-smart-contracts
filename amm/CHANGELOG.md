# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Features

- [move] Added CreatePool event which emits on pool creation ([afc41a4](https://github.com/kunalabs-io/sui-smart-contracts/commit/afc41a48e63faad10516cfbc5d3596f85281bb57))
- [move] Added periphery functions to the smart contract in order to deal with Coin objects of different values ([a7b1488](https://github.com/kunalabs-io/sui-smart-contracts/commit/a7b14886f782e4aaee19b589a943784d31cc3923))

### Fixes

- [move] Fixed amm tests for devnet-0.12 ([bdfbb6b](https://github.com/kunalabs-io/sui-smart-contracts/commit/bdfbb6b3972c31c01aae28dc753404779c510a4a))
- [move] Fixed admin fee calculation formula ([1e8eb44](https://github.com/kunalabs-io/sui-smart-contracts/commit/1e8eb44ffd32e948d3f631d0e67b5097f565a32e))
- [move] Removed move u128 and u256 math libraries and use std lib instead ([dc485a9](https://github.com/kunalabs-io/sui-smart-contracts/commit/dc485a987f978b51204d5ef9af9a915af3f2daa9))

### Breaking

- [move] Renamed `new_pool` to `create_pool` ([7044139](https://github.com/kunalabs-io/sui-smart-contracts/commit/7044139e91387c4fea29a9c0c41a95823f7404b9))
- [move] Enforce one pool can exist per currency pair ([8019057](https://github.com/kunalabs-io/sui-smart-contracts/commit/80190572b9d683dfb4b6fe0964083b01f5e9a9a8))
- [move] Use the standard `Coin` instead of `LPCoin` to represent liquidity tokens ([fdf342f](https://github.com/kunalabs-io/sui-smart-contracts/commit/fdf342f05005c7448735318b7f76c760b4b25b81))
