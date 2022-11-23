export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x9174c53bddf6d51252e92954c6b26783e7314d88',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
