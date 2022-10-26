import { WalletAdapter } from '@mysten/wallet-adapter-base'

export async function getWalletAddress(wallet: WalletAdapter): Promise<string> {
  const accs = await wallet.getAccounts()
  return accs[0]
}
