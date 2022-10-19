import { SuiWalletAdapter } from '@mysten/wallet-adapter-all-wallets'

export async function getWalletAddress(wallet: SuiWalletAdapter): Promise<string> {
  const accs = await wallet.getAccounts()
  return accs[0]
}
