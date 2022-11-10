export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0xffc427e5aa12f25423f579e9acb512c39d720988',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
