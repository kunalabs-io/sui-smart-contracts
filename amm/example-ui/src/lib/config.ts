export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x5326f5bbb39a5cdcbdc79500ebfec277e6e3890f',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
