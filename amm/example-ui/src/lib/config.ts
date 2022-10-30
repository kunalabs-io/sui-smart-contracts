export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x6ec712486c2ce6042d363ffbbf00bec8ba0915d7',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
