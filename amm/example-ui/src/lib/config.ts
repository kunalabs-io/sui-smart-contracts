export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0xa9743fa4d1b322808108d2e81d70d23b0ea9ed6f',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
