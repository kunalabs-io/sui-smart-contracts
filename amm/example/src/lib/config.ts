export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x9cfdd454975b82d30e3d2f3ddc5fcbc3baa1be7e',
  ammDefaultPools: [],
}
