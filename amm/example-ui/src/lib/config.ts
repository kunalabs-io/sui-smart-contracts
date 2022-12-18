export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammPoolRegistryObj: string
  readonly ammDefaultPools: string[]
  readonly fetchPoolsViaEvents: boolean
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',
  ammPackageId: '0x72de5feb63c0ab6ed1cda7e5b367f3d0a999add7',
  ammPoolRegistryObj: '0x288ec2236c98e9a6796b6455e9d8057ce14d2ba8',
  ammDefaultPools: [],
  fetchPoolsViaEvents: true,
}
