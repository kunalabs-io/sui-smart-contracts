export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x667f8808bfbd566706de0e19d243fd2c5f0900e9',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
