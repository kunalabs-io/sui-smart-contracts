export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x934ac8360b040b0bf395321f95b24e187ae097d3',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
