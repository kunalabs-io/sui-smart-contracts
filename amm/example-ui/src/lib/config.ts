export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x1dbbcd817a74aa721ae76ebda4c9afc0a6d7c3b3',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
