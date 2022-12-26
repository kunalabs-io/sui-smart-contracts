import { Provider, Coin as SuiCoin, JsonRpcProvider, getObjectExistsResponse } from '@mysten/sui.js'
import { WalletAdapter } from '@mysten/wallet-adapter-base'
import { PACKAGE_ID } from './core'
import { LP, PoolCreationEvent } from './core/amm/structs'
import { Type } from './core/type'
import { Coin, suiCoinToCoin } from './framework/coin'
import { Pool } from './pool'

export async function getWalletAddress(wallet: WalletAdapter): Promise<string> {
  const accs = await wallet.getAccounts()
  return accs[0]
}

export async function fetchUserLpCoins(provider: Provider, wallet: WalletAdapter): Promise<Coin[]> {
  const addr = await getWalletAddress(wallet)
  const infos = (await provider.getObjectsOwnedByAddress(addr)).filter(obj => {
    return SuiCoin.isCoin(obj) && LP.isLp(SuiCoin.getCoinTypeArg(obj)!)
  })

  return (await (provider as JsonRpcProvider).getObjectBatch(infos.map(info => info.objectId))).map(
    suiCoinToCoin
  )
}

export async function fetchAllPools(provider: Provider): Promise<Pool[]> {
  const poolIds: string[] = []

  const events = await provider.getEvents(
    { MoveEvent: `${PACKAGE_ID}::amm::PoolCreationEvent` },
    null,
    null,
    'descending'
  )
  events.data.forEach(envelope => {
    const event = envelope.event
    if (!('moveEvent' in event)) {
      throw new Error('Not a MoveEvent')
    }

    const dec = PoolCreationEvent.fromBcs(event.moveEvent.bcs, 'base64')
    poolIds.push(dec.poolId)
  })

  const poolObjs = await (provider as JsonRpcProvider).getObjectBatch(poolIds)
  return await Promise.all(
    poolObjs.map(async res => {
      const obj = getObjectExistsResponse(res)
      if (obj == undefined) {
        throw new Error(`object does not exist`)
      }
      return Pool.fromSuiObject(obj)
    })
  )
}

export function selectPoolForPair(pools: Pool[], currencyTypes: [Type, Type]): Pool | undefined {
  for (const pool of pools) {
    const [ptA, ptB] = pool.state.typeArgs

    if (
      (ptA === currencyTypes[0] && ptB === currencyTypes[1]) ||
      (ptA === currencyTypes[1] && ptB === currencyTypes[0])
    ) {
      return pool
    }
  }
}

export function selectPoolForLpCoin(pools: Pool[], lpCoin: Coin): Pool | undefined {
  const args = LP.parseTypeArgs(lpCoin.typeArg)
  return selectPoolForPair(pools, args)
}
