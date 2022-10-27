export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly exampleCoinPackageId: string
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',

  ammPackageId: '0x12e1d63c87a36e3be3d6b85f7c2975e2a89684aa',
  exampleCoinPackageId: '0x0ae02752bcdc66dc9f2393a73b3ade083bc4df71',

  ammDefaultPools: [],
}
