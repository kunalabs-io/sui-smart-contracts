export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammPoolListObj: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0xfd67f27af3de7b14b90e4bffbe42541496cd7e99',
  ammPoolListObj: '0xe6625a042646bdeaaa91bbb151c7c3f63aebd301',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
