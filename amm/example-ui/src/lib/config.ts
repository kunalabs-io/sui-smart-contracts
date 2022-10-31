export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x942ce9ccae3c4228b49327a02470403bd176b609',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
