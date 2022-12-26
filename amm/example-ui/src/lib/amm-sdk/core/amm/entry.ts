import { ObjectId, SignableTransaction } from '@mysten/sui.js'
import { PACKAGE_ID } from '..'
import { Type } from '../type'

export interface CreatePoolArgs {
  list: ObjectId
  initA: ObjectId
  initB: ObjectId
  lpFeeBps: bigint
  adminFeePct: bigint
}

export function create_pool(typeArgs: [Type, Type], args: CreatePoolArgs): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'amm',
      function: 'create_pool_',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [
        args.list,
        args.initA,
        args.initB,
        args.lpFeeBps.toString(),
        args.adminFeePct.toString(),
      ],
      gasBudget: 10000,
    },
  }
}

export interface DepositArgs {
  pool: ObjectId
  inputA: ObjectId
  inputB: ObjectId
  minLpOut: bigint
}

export function deposit(typeArgs: [Type, Type], args: DepositArgs): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'amm',
      function: 'deposit_',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [args.pool, args.inputA, args.inputB, args.minLpOut.toString()],
      gasBudget: 10000,
    },
  }
}

export interface WithdrawArgs {
  pool: ObjectId
  lpIn: ObjectId
  minAOut: bigint
  minBOut: bigint
}

export function withdraw(typeArgs: [Type, Type], args: WithdrawArgs): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'amm',
      function: 'withdraw_',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [
        args.pool,
        args.lpIn.toString(),
        args.minAOut.toString(),
        args.minBOut.toString(),
      ],
      gasBudget: 10000,
    },
  }
}

export interface SwapAArgs {
  pool: ObjectId
  input: ObjectId
  minOut: bigint
}

export function swapA(typeArgs: [Type, Type], args: SwapAArgs): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'amm',
      function: 'swap_a_',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [args.pool, args.input, args.minOut.toString()],
      gasBudget: 10000,
    },
  }
}

export interface SwapBArgs {
  pool: ObjectId
  input: ObjectId
  minOut: bigint
}

export function swapB(typeArgs: [Type, Type], args: SwapAArgs): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'amm',
      function: 'swap_b_',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [args.pool, args.input, args.minOut.toString()],
      gasBudget: 10000,
    },
  }
}

export interface AdminWithdrawFeesArgs {
  pool: ObjectId
  adminCap: ObjectId
  amount: bigint
}

export function adminWithdrawFees(
  typeArgs: [Type, Type],
  args: AdminWithdrawFeesArgs
): SignableTransaction {
  return {
    kind: 'moveCall',
    data: {
      packageObjectId: PACKAGE_ID,
      module: 'amm',
      function: 'admin_withdraw_fees_',
      typeArguments: [typeArgs[0], typeArgs[1]],
      arguments: [args.pool, args.adminCap, args.amount.toString()],
      gasBudget: 10000,
    },
  }
}
