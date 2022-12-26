import {
  ObjectId,
  Provider,
  Coin as SuiCoin,
  GetObjectDataResponse,
  JsonRpcProvider,
} from '@mysten/sui.js'
import { WalletAdapter } from '@mysten/wallet-adapter-base'
import { Amount } from './amount'
import { Type } from '../core/type'
import { getWalletAddress } from '../util'
import { Balance } from './balance'

export interface CoinMetadataFields {
  id: ObjectId
  decimals: number
  name: string
  symbol: string
  description: string
  iconUrl?: string
}

export class CoinMetadata {
  readonly typeArg: Type
  readonly id: ObjectId
  readonly decimals: number
  readonly name: string
  readonly symbol: string
  readonly description: string
  readonly iconUrl?: string

  constructor(typeArg: Type, fields: CoinMetadataFields) {
    this.typeArg = typeArg
    this.id = fields.id
    this.decimals = fields.decimals
    this.name = fields.name
    this.symbol = fields.symbol
    this.description = fields.description
    this.iconUrl = fields.iconUrl
  }

  newAmount(value: bigint): Amount {
    return Amount.fromInt(value, this.decimals)
  }
}

export class Coin {
  readonly typeArg: Type
  readonly id: ObjectId
  readonly balance: Balance

  constructor(typeArg: Type, id: ObjectId, balance: bigint) {
    this.typeArg = typeArg
    this.id = id
    this.balance = new Balance(typeArg, balance)
  }
}

export function suiCoinToCoin(coin: GetObjectDataResponse): Coin {
  if (!SuiCoin.isCoin(coin)) {
    throw new Error('Not a Coin')
  }
  return new Coin(SuiCoin.getCoinTypeArg(coin)!, SuiCoin.getID(coin), SuiCoin.getBalance(coin)!)
}

export async function getUserCoins(provider: Provider, wallet: WalletAdapter) {
  const addr = await getWalletAddress(wallet)
  const coinInfos = (await provider.getObjectsOwnedByAddress(addr)).filter(SuiCoin.getCoinTypeArg)
  const coins = (
    await (provider as JsonRpcProvider).getObjectBatch(coinInfos.map(obj => obj.objectId))
  ).map(suiCoinToCoin)

  return coins
}

export function totalBalance(coins: Coin[]): bigint {
  return coins.reduce((acc, coin) => acc + coin.balance.value, BigInt(0))
}

export function selectCoinWithBalanceGreaterThanOrEqual(
  coins: Coin[],
  balance: bigint
): Coin | undefined {
  return coins.find(coin => coin.balance.value >= balance)
}

export function sortByBalance(coins: Coin[]): Coin[] {
  return coins.sort((a, b) => {
    if (a.balance.value < b.balance.value) {
      return -1
    } else if (a.balance.value > b.balance.value) {
      return 1
    } else {
      return 0
    }
  })
}

export function selectCoinsWithBalanceGreaterThanOrEqual(coins: Coin[], balance: bigint): Coin[] {
  return sortByBalance(coins.filter(coin => coin.balance.value >= balance))
}

export async function getOrCreateCoinOfLargeEnoughBalance(
  provider: Provider,
  wallet: WalletAdapter,
  coinType: Type,
  balance: bigint
): Promise<Coin> {
  const coins = (await getUserCoins(provider, wallet)).filter(coin => coin.typeArg === coinType)
  if (totalBalance(coins) < balance) {
    throw new Error(
      `Balances of ${coinType} Coins in the wallet don't amount to ${balance.toString()}`
    )
  }

  const coin = selectCoinWithBalanceGreaterThanOrEqual(coins, balance)
  if (coin !== undefined) {
    return coin
  }

  const inputCoins = selectCoinsWithBalanceGreaterThanOrEqual(coins, balance)
  const addr = await getWalletAddress(wallet)
  const res = await wallet.signAndExecuteTransaction({
    kind: 'pay',
    data: {
      inputCoins: inputCoins.map(coin => coin.id),
      recipients: [addr],
      amounts: [Number(balance)],
      gasBudget: 10000,
    },
  })

  const createdId = res!.effects.created![0].reference.objectId
  const newCoin = await provider.getObject(createdId)

  return suiCoinToCoin(newCoin)
}

/// Returns a list of unique coin types.
export function getUniqueCoinTypes(coins: Coin[]): Type[] {
  return [...new Set(coins.map(coin => coin.typeArg))]
}

/// Returns a map from coin type to the total balance of coins of that type.
export function getCoinBalances(coins: Coin[]): Map<Type, bigint> {
  const balances = new Map<Type, bigint>()
  for (const coin of coins) {
    const balance = balances.get(coin.typeArg)
    if (balance === undefined) {
      balances.set(coin.typeArg, coin.balance.value)
    } else {
      balances.set(coin.typeArg, balance + coin.balance.value)
    }
  }
  return balances
}
