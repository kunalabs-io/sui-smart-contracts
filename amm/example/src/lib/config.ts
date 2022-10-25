export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly exampleCoinPackageId: string
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',

  ammPackageId: '0x9d9635aab271ffe3f091734ec3d4cbba913cda81',
  exampleCoinPackageId: '0xa68c2da53dd13519ef829ffbf557adcf21ba2c84',

  ammDefaultPools: ['0xd89ae379d092c75f5ceb2491f9613a0c50271df7'],
}
