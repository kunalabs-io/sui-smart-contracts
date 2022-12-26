import { JsonRpcProvider, TypeTag } from '@mysten/sui.js'
import { CONFIG } from '../config'
import { tagToType } from './core/type'
import { CoinMetadata } from './framework/coin'

const provider = new JsonRpcProvider(CONFIG.rpcUrl)
const cache = new Map<string, CoinMetadata>()

export class CoinMetadataLoader {
  static async loadMetadata(type: TypeTag | string): Promise<CoinMetadata> {
    let typeStr: string
    if (typeof type === 'string') {
      typeStr = type
    } else {
      typeStr = tagToType(type)
    }

    if (cache.has(typeStr)) {
      return cache.get(typeStr)!
    }

    try {
      const res = await provider.getCoinMetadata(typeStr)
      const metadata = new CoinMetadata(typeStr, {
        id: res.id!,
        decimals: res.decimals,
        name: res.name,
        symbol: res.symbol,
        description: res.description,
        iconUrl: res.iconUrl || undefined,
      })

      cache.set(typeStr, metadata)

      return metadata
    } catch (e) {
      throw new Error(`failed to load metadata for type ${typeStr}`)
    }
  }
}
