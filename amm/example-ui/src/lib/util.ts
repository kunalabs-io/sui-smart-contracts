import { normalizeSuiAddress } from '@mysten/sui.js'

export function ellipsizeAddress(addr: string, length = 5): string {
  const norm = normalizeSuiAddress(addr)
  return `${norm.substring(0, length + 2)}...${norm.substring(norm.length - length)}`
}
