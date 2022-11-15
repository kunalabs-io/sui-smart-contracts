export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x50b4c3a3080d617726c3193d6bc1f25f5df0075',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
