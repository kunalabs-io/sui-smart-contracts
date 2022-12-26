import {
  ObjectId,
  Provider,
  SignableTransaction,
  SuiObject,
  SuiTransactionResponse,
} from '@mysten/sui.js'
import { ceilDiv, min, sqrt } from '../bigint-math'
import { Amount } from './framework/amount'
import { CoinMetadataLoader } from './coin-metadata-loader'
import { Pool as PoolObj } from './core/amm/structs'
import {
  maybeSplitThenCreatePool,
  maybeSplitThenDeposit,
  maybeSplitThenSwapA,
  maybeSplitThenSwapB,
  maybeSplitThenWithdraw,
} from './core/periphery/entry'
import { CoinMetadata } from './framework/coin'
import { WalletAdapter } from '@mysten/wallet-adapter-base'
import { Type } from './core/type'
import { getOrCreateCoinOfLargeEnoughBalance } from './framework/coin'

const BPS_IN_100_PCT = BigInt(100 * 100)

export interface CreatePoolArgs {
  registry: ObjectId
  amountA: bigint
  amountB: bigint
  lpFeeBps: number
  adminFeePct: number
}

export interface DepositArgs {
  amountA: bigint
  amountB: bigint
  maxSlippagePct: number
}

export interface WithdrawArgs {
  lpIn: ObjectId
  amount: bigint
  maxSlippagePct: number
}

export interface SwapArgs {
  inputType: Type
  amount: bigint
  maxSlippagePct: number
}

export class Pool {
  readonly id: ObjectId

  constructor(public state: PoolObj, readonly coinMetadata: [CoinMetadata, CoinMetadata]) {
    this.id = state.id
  }

  static async fromSuiObject(obj: SuiObject): Promise<Pool> {
    const state = PoolObj.fromSuiObject(obj)
    const metadata = await Promise.all([
      CoinMetadataLoader.loadMetadata(state.typeArgs[0]),
      CoinMetadataLoader.loadMetadata(state.typeArgs[1]),
    ])
    return new Pool(state, metadata)
  }

  static async fetchFromAddress(provider: Provider, id: ObjectId): Promise<Pool> {
    const state = await PoolObj.fetch(provider, id)
    const metadata = await Promise.all([
      CoinMetadataLoader.loadMetadata(state.typeArgs[0]),
      CoinMetadataLoader.loadMetadata(state.typeArgs[1]),
    ])
    return new Pool(state, metadata)
  }

  async updateState(provider: Provider) {
    this.state = await PoolObj.fetch(provider, this.state.id)
  }

  private static maybeReorderCreatePoolParams(
    typeArgs: [Type, Type],
    params: CreatePoolArgs
  ): [[Type, Type], CreatePoolArgs] {
    if (typeArgs[0] < typeArgs[1]) {
      return [typeArgs, params]
    } else {
      return [
        [typeArgs[1], typeArgs[0]],
        {
          ...params,
          amountA: params.amountB,
          amountB: params.amountA,
        },
      ]
    }
  }

  static async createPool(
    provider: Provider,
    wallet: WalletAdapter,
    typeArgs: [Type, Type],
    args: CreatePoolArgs
  ) {
    ;[typeArgs, args] = this.maybeReorderCreatePoolParams(typeArgs, args)

    const [inputA, inputB] = await Promise.all([
      await getOrCreateCoinOfLargeEnoughBalance(provider, wallet, typeArgs[0], args.amountA),
      await getOrCreateCoinOfLargeEnoughBalance(provider, wallet, typeArgs[1], args.amountB),
    ])

    const tx = maybeSplitThenCreatePool(typeArgs, {
      registry: args.registry,
      inputA: inputA.id,
      amountA: args.amountA,
      inputB: inputB.id,
      amountB: args.amountB,
      lpFeeBps: BigInt(args.lpFeeBps),
      adminFeePct: BigInt(args.adminFeePct),
    })
    await wallet.signAndExecuteTransaction(tx)
  }

  async deposit(provider: Provider, wallet: WalletAdapter, args: DepositArgs) {
    const [inputA, inputB] = await Promise.all([
      await getOrCreateCoinOfLargeEnoughBalance(
        provider,
        wallet,
        this.state.typeArgs[0],
        args.amountA
      ),
      await getOrCreateCoinOfLargeEnoughBalance(
        provider,
        wallet,
        this.state.typeArgs[1],
        args.amountB
      ),
    ])

    const expLpOut = this.calcLpOut(args.amountA, args.amountB)
    const minLpOut = ceilDiv(expLpOut.int * BigInt(100 - args.maxSlippagePct), 100n)

    const tx = maybeSplitThenDeposit(this.state.typeArgs, {
      pool: this.state.id,
      inputA: inputA.id,
      amountA: args.amountA,
      inputB: inputB.id,
      amountB: args.amountB,
      minLpOut,
    })
    return await wallet.signAndExecuteTransaction(tx)
  }

  withdrawTx(args: WithdrawArgs): SignableTransaction {
    // TODO: make slippage be a percentage on the price change rather than on the output amounts
    const [expA, expB] = this.calcLpValue(args.amount)
    const minAOut = ceilDiv(expA.int * BigInt(100 - args.maxSlippagePct), 100n)
    const minBOut = ceilDiv(expB.int * BigInt(100 - args.maxSlippagePct), 100n)

    return maybeSplitThenWithdraw(this.state.typeArgs, {
      pool: this.state.id,
      lpIn: args.lpIn,
      amount: args.amount,
      minAOut,
      minBOut,
    })
  }

  async withdraw(wallet: WalletAdapter, args: WithdrawArgs): Promise<SuiTransactionResponse> {
    const tx = this.withdrawTx(args)
    return await wallet.signAndExecuteTransaction(tx)
  }

  async swap(
    provider: Provider,
    wallet: WalletAdapter,
    args: SwapArgs
  ): Promise<SuiTransactionResponse> {
    let fun: typeof maybeSplitThenSwapA | typeof maybeSplitThenSwapB
    if (args.inputType === this.state.typeArgs[0]) {
      fun = maybeSplitThenSwapA
    } else if (args.inputType === this.state.typeArgs[1]) {
      fun = maybeSplitThenSwapB
    } else {
      throw new Error('Invalid input coin')
    }

    const input = await getOrCreateCoinOfLargeEnoughBalance(
      provider,
      wallet,
      args.inputType,
      args.amount
    )

    const expOut = this.calcSwapOut(args.inputType, args.amount)
    const minOut = (expOut.int * (100n - BigInt(args.maxSlippagePct))) / 100n

    const tx = fun(this.state.typeArgs, {
      pool: this.state.id,
      input: input.id,
      amount: args.amount,
      minOut,
    })
    return await wallet.signAndExecuteTransaction(tx)
  }

  /**
   * Validates the input amount and returns the following values:
   *  - thisValue: the amount of input coin
   *  - thisPoolValue: the amount of input coin in the pool
   *  - otherPoolValue: the amount of other coin in the pool
   *  - thisMetadata: the metadata of input coin
   *  - otherMetadata: the metadata of other coin
   */
  private validateAmount(
    type: Type,
    amount: Amount | bigint
  ): [bigint, bigint, bigint, CoinMetadata, CoinMetadata] {
    let thisPoolValue: bigint
    let otherPoolValue: bigint
    let thisMetadata: CoinMetadata
    let otherMetadata: CoinMetadata

    if (type === this.state.typeArgs[0]) {
      ;[thisPoolValue, otherPoolValue] = [this.state.balanceA.value, this.state.balanceB.value]
      ;[thisMetadata, otherMetadata] = [this.coinMetadata[0], this.coinMetadata[1]]
    } else if (type === this.state.typeArgs[1]) {
      ;[thisPoolValue, otherPoolValue] = [this.state.balanceB.value, this.state.balanceA.value]
      ;[thisMetadata, otherMetadata] = [this.coinMetadata[1], this.coinMetadata[0]]
    } else {
      throw new Error('invalid coin type')
    }

    let thisValue: bigint
    if (typeof amount === 'bigint') {
      thisValue = amount
    } else {
      thisValue = amount.int
      if (amount.decimals !== thisMetadata.decimals) {
        throw new Error('invalid input amount decimals')
      }
    }

    return [thisValue, thisPoolValue, otherPoolValue, thisMetadata, otherMetadata]
  }

  /**
   * Calculates the amount of output coin that can be swapped out for the given amount of input coin.
   */
  calcSwapOut(inType: Type, inAmount: Amount | bigint): Amount {
    const [inValue, inPoolValue, outPoolValue, , outMetadata] = this.validateAmount(
      inType,
      inAmount
    )

    const lpFeeValue = ceilDiv(inValue * this.state.lpFeeBps, BPS_IN_100_PCT)
    const inAfterLpFee = inValue - lpFeeValue
    const outValue = (inAfterLpFee * outPoolValue) / (inPoolValue + inAfterLpFee)

    return Amount.fromInt(outValue, outMetadata.decimals)
  }

  /**
   * Calculates the amount of input coin needed to swap out the given amount of output coin.
   */
  estSwapInFromOut(outType: Type, outAmount: Amount | bigint): Amount {
    const [outValue, outPoolValue, inPoolValue, , inMetadata] = this.validateAmount(
      outType,
      outAmount
    )

    const inAfterLpFee = ceilDiv(outValue * inPoolValue, outPoolValue - outValue)
    const inValue = ceilDiv(inAfterLpFee * BPS_IN_100_PCT, BPS_IN_100_PCT - this.state.lpFeeBps)

    return Amount.fromInt(inValue, inMetadata.decimals)
  }

  /**
   * Calculates the amount of other coin needed to deposit given the amount of input coin.
   * Also returns the amount of LP token that will be minted.
   */
  calcDepositOtherAmount(type: Type, amount: Amount | bigint): [Amount, Amount] {
    const [thisValue, thisPoolValue, otherPoolValue, , otherMetadata] = this.validateAmount(
      type,
      amount
    )

    const otherValue = (thisValue * otherPoolValue) / thisPoolValue
    const lpValue = (thisValue * this.state.lpSupply.value) / thisPoolValue

    // TODO: get the number of decimals on LP coin right
    return [Amount.fromInt(otherValue, otherMetadata.decimals), Amount.fromInt(lpValue, 0)]
  }

  calcLpValue(lpAmount: bigint): [Amount, Amount] {
    const [balanceA, balanceB, poolLpAmount] = [
      this.state.balanceA.value,
      this.state.balanceB.value,
      this.state.lpSupply.value,
    ]

    if (lpAmount === 0n || balanceA === 0n || balanceB === 0n) {
      return [
        Amount.fromInt(0n, this.coinMetadata[0].decimals),
        Amount.fromInt(0n, this.coinMetadata[1].decimals),
      ]
    }

    const amountA = (balanceA * lpAmount) / poolLpAmount
    const amountB = (balanceB * lpAmount) / poolLpAmount

    return [
      Amount.fromInt(amountA, this.coinMetadata[0].decimals),
      Amount.fromInt(amountB, this.coinMetadata[1].decimals),
    ]
  }

  calcLpOut(amountA: bigint, amountB: bigint): Amount {
    const [balanceA, balanceB, lpSupply] = [
      this.state.balanceA.value,
      this.state.balanceB.value,
      this.state.lpSupply.value,
    ]

    let lpOut: bigint
    if (balanceA === 0n && balanceB === 0n) {
      lpOut = sqrt(amountA * amountB)
    } else {
      const expLpOutBasedOnA = (amountA * lpSupply) / balanceA
      const expLpOutBasedOnB = (amountB * lpSupply) / balanceB
      lpOut = min(expLpOutBasedOnA, expLpOutBasedOnB)
    }

    return Amount.fromInt(lpOut, 0)
  }
}
