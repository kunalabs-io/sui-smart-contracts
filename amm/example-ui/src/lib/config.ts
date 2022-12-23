export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammPoolRegistryObj: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x5a4cff4897fef7722a953f6b3f458d5b98afaf2e',
  ammPoolRegistryObj: '0x601f51e99c19ea8f4b708d4040436523271b2ff7',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
