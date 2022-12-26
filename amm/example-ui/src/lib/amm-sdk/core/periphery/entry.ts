import { ObjectId, SignableTransaction } from '@mysten/sui.js'
import { PACKAGE_ID } from '../index'
import { Type } from '../type'

export interface MaybeSplitThenCreatePoolArgs {
  registry: ObjectId
  inputA: ObjectId
  amountA: bigint
  inputB: ObjectId
  amountB: bigint
  lpFeeBps: bigint
  adminFeePct: bigint
}

export function maybeSplitThenCreatePool(
  typeArgs: [Type, Type],
  args: MaybeSplitThenCreatePoolArgs
): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'periphery',
      function: 'maybe_split_then_create_pool',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [
        args.registry,
        args.inputA,
        args.amountA.toString(),
        args.inputB,
        args.amountB.toString(),
        args.lpFeeBps.toString(),
        args.adminFeePct.toString(),
      ],
      gasBudget: 10000,
    },
  }
}

export interface MaybeSplitThenSwapAArgs {
  pool: ObjectId
  input: ObjectId
  amount: bigint
  minOut: bigint
}

export function maybeSplitThenSwapA(
  typeArgs: [Type, Type],
  args: MaybeSplitThenSwapAArgs
): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'periphery',
      function: 'maybe_split_then_swap_a',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [args.pool, args.input, args.amount.toString(), args.minOut.toString()],
      gasBudget: 10000,
    },
  }
}

export interface MaybeSplitThenSwapBArgs {
  pool: ObjectId
  input: ObjectId
  amount: bigint
  minOut: bigint
}

export function maybeSplitThenSwapB(
  typeArgs: [Type, Type],
  args: MaybeSplitThenSwapBArgs
): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'periphery',
      function: 'maybe_split_then_swap_b',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [args.pool, args.input, args.amount.toString(), args.minOut.toString()],
      gasBudget: 10000,
    },
  }
}

export interface MaybeSplitThenDepositArgs {
  pool: ObjectId
  inputA: ObjectId
  amountA: bigint
  inputB: ObjectId
  amountB: bigint
  minLpOut: bigint
}

export function maybeSplitThenDeposit(
  typeArgs: [Type, Type],
  args: MaybeSplitThenDepositArgs
): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'periphery',
      function: 'maybe_split_then_deposit',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [
        args.pool,
        args.inputA,
        args.amountA.toString(),
        args.inputB,
        args.amountB.toString(),
        args.minLpOut.toString(),
      ],
      gasBudget: 10000,
    },
  }
}

export interface MaybeSplitThenWithdrawArgs {
  pool: ObjectId
  lpIn: ObjectId
  amount: bigint
  minAOut: bigint
  minBOut: bigint
}

export function maybeSplitThenWithdraw(
  typeArgs: [Type, Type],
  args: MaybeSplitThenWithdrawArgs
): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'periphery',
      function: 'maybe_split_then_withdraw',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [
        args.pool,
        args.lpIn,
        args.amount.toString(),
        args.minAOut.toString(),
        args.minBOut.toString(),
      ],
      gasBudget: 10000,
    },
  }
}
