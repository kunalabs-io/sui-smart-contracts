export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x883bb1ffbd7ec7dd653389b3a29a9f274e92cb91',
  ammDefaultPools: [],
}
