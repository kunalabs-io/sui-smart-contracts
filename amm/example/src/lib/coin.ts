import { Coin, GetObjectDataResponse, JsonRpcProvider } from '@mysten/sui.js'
import { WalletAdapter } from '@mysten/wallet-adapter-base'
import { getWalletAddress } from './util'

interface CoinInfo {
  objectID: string
  type: string
  symbol: string
  balance: bigint
}

export async function getUserCoins(provider: JsonRpcProvider, wallet: WalletAdapter) {
  const addr = await getWalletAddress(wallet)
  const coinInfos = (await provider.getObjectsOwnedByAddress(addr)).filter(Coin.isCoin)
  const coins = await provider.getObjectBatch(coinInfos.map(obj => obj.objectId))

  return coins
}

export function coinInfo(coin: GetObjectDataResponse): CoinInfo {
  if (!Coin.isCoin(coin)) {
    throw new Error('not a coin')
  }

  const type = Coin.getCoinTypeArg(coin)!

  return {
    objectID: Coin.getID(coin),
    type,
    symbol: Coin.getCoinSymbol(type),
    balance: Coin.getBalance(coin)!,
  }
}

export function partitionCoinsByType(
  coins: Array<GetObjectDataResponse>
): Map<string, Array<GetObjectDataResponse>> {
  const ret = new Map<string, Array<GetObjectDataResponse>>()
  coins.forEach(coin => {
    const info = coinInfo(coin)

    let arr = ret.get(info.type)
    if (arr === undefined) {
      arr = []
      ret.set(info.type, arr)
    }
    arr.push(coin)
  })

  return ret
}

export function getUniqueCoinTypes(coins: GetObjectDataResponse[]): string[] {
  return Array.from(partitionCoinsByType(coins).keys())
}

export function getCoinBalances(coins: Array<GetObjectDataResponse>): Map<string, bigint> {
  const parts = partitionCoinsByType(coins)

  const ret = new Map<string, bigint>()
  parts.forEach((coins, type) => {
    ret.set(type, Coin.totalBalance(coins))
  })

  return ret
}

function getAllCoinsOfType(
  coins: GetObjectDataResponse[],
  typeArg: string
): GetObjectDataResponse[] {
  const parts = partitionCoinsByType(coins)
  return parts.get(typeArg) || []
}

export async function getOrCreateCoinOfExactBalance(
  provider: JsonRpcProvider,
  wallet: WalletAdapter,
  coinType: string,
  balance: bigint
): Promise<GetObjectDataResponse> {
  if (wallet.signAndExecuteTransaction === undefined) {
    throw new Error('Wallet not supported')
  }

  // select appropriate coins
  const coins = getAllCoinsOfType(await getUserCoins(provider, wallet), coinType)
  const symbol = Coin.getCoinSymbol(coinType)
  if (coins.length === 0) {
    throw new Error(`No ${symbol} Coins found in wallet!`)
  }

  // check whether an exact coin already exists and return if it does
  for (const coin of coins) {
    if (Coin.getBalance(coin) === balance) {
      return coin
    }
  }

  // combine coins to exact balance
  const inputCoins = Coin.selectCoinSetWithCombinedBalanceGreaterThanOrEqual(coins, balance)
  if (inputCoins.length === 0) {
    throw new Error(
      `Balances of ${symbol} Coins in the wallet don't amount to ${balance.toString()}`
    )
  }

  const addr = await getWalletAddress(wallet)
  const res = await wallet.signAndExecuteTransaction({
    kind: 'pay',
    data: {
      inputCoins: inputCoins.map(Coin.getID),
      recipients: [addr],
      amounts: [balance.toString() as unknown as number],
      gasBudget: 10000,
    },
  })
  const createdId = res?.effects.created![0].reference.objectId
  const exactCoin = await provider.getObject(createdId!)

  console.debug(res)

  return exactCoin
}

export async function getOrCreateCoinOfLargeEnoughBalance(
  provider: JsonRpcProvider,
  wallet: WalletAdapter,
  coinType: string,
  balance: bigint
): Promise<GetObjectDataResponse> {
  if (wallet.signAndExecuteTransaction === undefined) {
    throw new Error('Wallet not supported')
  }

  const coins = getAllCoinsOfType(await getUserCoins(provider, wallet), coinType)
  if (Coin.totalBalance(coins) < balance) {
    const symbol = Coin.getCoinSymbol(coinType)
    throw new Error(
      `Balances of ${symbol} Coins in the wallet don't amount to ${balance.toString()}`
    )
  }

  const coin = Coin.selectCoinWithBalanceGreaterThanOrEqual(coins, balance)
  if (coin !== undefined) {
    return coin as GetObjectDataResponse
  }

  const inputCoins = Coin.selectCoinsWithBalanceGreaterThanOrEqual(coins, balance)
  const addr = await getWalletAddress(wallet)
  const res = await wallet.signAndExecuteTransaction({
    kind: 'pay',
    data: {
      inputCoins: inputCoins.map(Coin.getID),
      recipients: [addr],
      amounts: [Number(balance)],
      gasBudget: 10000,
    },
  })

  const createdId = res!.effects.created![0].reference.objectId
  return await provider.getObject(createdId)
}
