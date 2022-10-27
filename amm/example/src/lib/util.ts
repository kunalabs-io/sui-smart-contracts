import { GetObjectDataResponse } from '@mysten/sui.js'
import { WalletAdapter } from '@mysten/wallet-adapter-base'
import { getPoolBalances } from './amm'

export async function getWalletAddress(wallet: WalletAdapter): Promise<string> {
  const accs = await wallet.getAccounts()
  return accs[0]
}

export function checkIfPoolIsEmpty(pool: GetObjectDataResponse) {
  const [balanceA, balanceB] = getPoolBalances(pool)
  return balanceA === 0n || balanceB === 0n
}
