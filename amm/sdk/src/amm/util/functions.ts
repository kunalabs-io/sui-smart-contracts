import { TransactionBlock } from '@mysten/sui.js'
import { Type } from 'framework/type'
import { PACKAGE_ID } from '..'
import { ObjectArg, obj } from 'framework/util'

export interface CreatePoolWithCoinsArgs {
  registry: ObjectArg
  initA: ObjectArg
  initB: ObjectArg
  lpFeeBps: bigint
  adminFeePct: bigint
}

/**
 * Calls `create_pool_with_coins` using Coins as input.
 *
 * @arguments (registry: &mut PoolRegistry, init_a: Coin<A>, init_b: Coin<B>, lp_fee_bps: u64, admin_fee_pct: u64, ctx: &mut TxContext)
 * @returns Coin<LP<A, B>>
 */
export function createPoolWithCoins(
  tx: TransactionBlock,
  typeArgs: [Type, Type],
  args: CreatePoolWithCoinsArgs
) {
  tx.moveCall({
    target: `${PACKAGE_ID}::util::create_pool_with_coins`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.registry),
      obj(tx, args.initA),
      obj(tx, args.initB),
      tx.pure(args.lpFeeBps),
      tx.pure(args.adminFeePct),
    ],
  })
}

export interface CreatePoolAndTransferLpToSenderArgs {
  registry: ObjectArg
  initA: ObjectArg
  initB: ObjectArg
  lpFeeBps: bigint
  adminFeePct: bigint
}

/**
 * Calls `pool::create` using Coins as input. Transfers the resulting LP Coin to the sender.
 *
 * @arguments (registry: &mut PoolRegistry, init_a: Coin<A>, init_b: Coin<B>, lp_fee_bps: u64, admin_fee_pct: u64, ctx: &mut TxContext)
 * @returns void
 */
export function createPoolAndTransferLpToSender(
  tx: TransactionBlock,
  typeArgs: [Type, Type],
  args: CreatePoolAndTransferLpToSenderArgs
) {
  tx.moveCall({
    target: `${PACKAGE_ID}::util::create_pool_and_transfer_lp_to_sender`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.registry),
      obj(tx, args.initA),
      obj(tx, args.initB),
      tx.pure(args.lpFeeBps),
      tx.pure(args.adminFeePct),
    ],
  })
}

export interface DepositCoinsArgs {
  pool: ObjectArg
  inputA: ObjectArg
  inputB: ObjectArg
  minLpOut: bigint
}

/**
 * Calls `pool::deposit` using Coins as input. Returns the remainder of the input
 * Coins and the LP Coin of appropriate value.
 *
 * @arguments (pool: &mut Pool<A, B>, input_a: Coin<A>, input_b: Coin<B>, min_lp_out: u64, ctx: &mut TxContext)
 * @returns (Coin<A>, Coin<B>, Coin<LP<A, B>>)
 */
export function depositCoins(tx: TransactionBlock, typeArgs: [Type, Type], args: DepositCoinsArgs) {
  return tx.moveCall({
    target: `${PACKAGE_ID}::util::deposit_coins`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.pool),
      obj(tx, args.inputA),
      obj(tx, args.inputB),
      tx.pure(args.minLpOut),
    ],
  })
}

export interface DepositAndTransferToSenderArgs {
  pool: ObjectArg
  inputA: ObjectArg
  inputB: ObjectArg
  minLpOut: bigint
}

/**
 * Calls `pool::deposit` using Coins as input. Transfers the remainder of the input
 * Coins and the LP Coin of appropriate value to the sender.
 *
 * @arguments (pool: &mut Pool<A, B>, input_a: Coin<A>, input_b: Coin<B>, min_lp_out: u64, ctx: &mut TxContext)
 * @returns void
 */
export function depositAndTransferToSender(
  tx: TransactionBlock,
  typeArgs: [Type, Type],
  args: DepositAndTransferToSenderArgs
) {
  const [TypeA, TypeB] = typeArgs
  return tx.moveCall({
    target: `${PACKAGE_ID}::util::deposit_and_transfer_to_sender`,
    typeArguments: [TypeA, TypeB],
    arguments: [
      obj(tx, args.pool),
      obj(tx, args.inputA),
      obj(tx, args.inputB),
      tx.pure(args.minLpOut),
    ],
  })
}

export interface WithdrawCoinsArgs {
  pool: ObjectArg
  lpIn: ObjectArg
  minAOut: bigint
  minBOut: bigint
}

/**
 * Calls `pool::withdraw` using Coin as input. Returns the withdrawn Coins.
 *
 * @arguments (pool: &mut Pool<A, B>, lp_in: Coin<LP<A, B>>, min_a_out: u64, min_b_out: u64, ctx: &mut TxContext)
 * @returns (Coin<A>, Coin<B>)
 */
export function withdrawCoins(
  tx: TransactionBlock,
  typeArgs: [Type, Type],
  args: WithdrawCoinsArgs
) {
  return tx.moveCall({
    target: `${PACKAGE_ID}::util::withdraw_coins`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.pool),
      obj(tx, args.lpIn),
      tx.pure(args.minAOut),
      tx.pure(args.minBOut),
    ],
  })
}

export interface WithdrawAndTransferToSenderArgs {
  pool: ObjectArg
  lpIn: ObjectArg
  minAOut: bigint
  minBOut: bigint
}

/**
 * Withdraws the provided amount of LP tokens from the pool and transfers the
 * corresponding amounts of A and B to the sender.
 *
 * @arguments (pool: &mut Pool<A, B>, lp_in: Coin<LP<A, B>>, min_a_out: u64, min_b_out: u64, ctx: &mut TxContext)
 * @returns void
 */
export function withdrawAndTransferToSender(
  tx: TransactionBlock,
  typeArgs: [Type, Type],
  args: WithdrawAndTransferToSenderArgs
) {
  const [TypeA, TypeB] = typeArgs
  return tx.moveCall({
    target: `${PACKAGE_ID}::util::withdraw_and_transfer_to_sender`,
    typeArguments: [TypeA, TypeB],
    arguments: [
      obj(tx, args.pool),
      obj(tx, args.lpIn),
      tx.pure(args.minAOut),
      tx.pure(args.minBOut),
    ],
  })
}

export interface SwapACoinArgs {
  pool: ObjectArg
  input: ObjectArg
  minOut: bigint
}

/**
 * Calls `pool::swap_a` using Coin as input. Returns the resulting Coin.
 *
 * @arguments (pool: &mut Pool<A, B>, input: Coin<A>, min_out: u64, ctx: &mut TxContext)
 * @returns Coin<B>
 */
export function swapACoin(tx: TransactionBlock, typeArgs: [Type, Type], args: SwapACoinArgs) {
  return tx.moveCall({
    target: `${PACKAGE_ID}::util::swap_a_coin`,
    typeArguments: typeArgs,
    arguments: [obj(tx, args.pool), obj(tx, args.input), tx.pure(args.minOut)],
  })
}

export interface SwapAAndTransferToSenderArgs {
  pool: ObjectArg
  input: ObjectArg
  minOut: bigint
}

/**
 * Calls `pool::swap_a` using Coin as input. Transfers the resulting Coin to the sender.
 *
 * @arguments (pool: &mut Pool<A, B>, input: Coin\<A\>, min_out: u64, ctx: &mut TxContext)
 * @returns void
 */
export function swapAAndTransferToSender(
  tx: TransactionBlock,
  typeArgs: [Type, Type],
  args: SwapAAndTransferToSenderArgs
) {
  return tx.moveCall({
    target: `${PACKAGE_ID}::util::swap_a_and_transfer_to_sender`,
    typeArguments: [typeArgs[0], typeArgs[1]],
    arguments: [obj(tx, args.pool), obj(tx, args.input), tx.pure(args.minOut)],
  })
}

export interface SwapBCoinArgs {
  pool: ObjectArg
  input: ObjectArg
  minOut: bigint
}

/**
 * Calls `pool::swap_b` using Coin as input. Returns the resulting Coin.
 *
 * @arguments (pool: &mut Pool<A, B>, input: Coin<B>, min_out: u64, ctx: &mut TxContext)
 * @returns Coin<A>
 */
export function swapBCoin(tx: TransactionBlock, typeArgs: [Type, Type], args: SwapBCoinArgs) {
  return tx.moveCall({
    target: `${PACKAGE_ID}::util::swap_b_coin`,
    typeArguments: typeArgs,
    arguments: [obj(tx, args.pool), obj(tx, args.input), tx.pure(args.minOut)],
  })
}

export interface SwapBAndTransferToSenderArgs {
  pool: ObjectArg
  input: ObjectArg
  minOut: bigint
}

/**
 * Calls `pool::swap_b` using Coin as input. Transfers the resulting Coin to the sender.
 *
 * @arguments (pool: &mut Pool<A, B>, input: Coin\<A\>, min_out: u64, ctx: &mut TxContext)
 * @returns void
 */
export function swapBAndTransferToSender(
  tx: TransactionBlock,
  typeArgs: [Type, Type],
  args: SwapBAndTransferToSenderArgs
) {
  return tx.moveCall({
    target: `${PACKAGE_ID}::util::swap_b_and_transfer_to_sender`,
    typeArguments: [typeArgs[0], typeArgs[1]],
    arguments: [obj(tx, args.pool), obj(tx, args.input), tx.pure(args.minOut)],
  })
}
