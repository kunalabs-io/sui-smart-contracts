export interface Config {
  readonly rpcUrl: string
  readonly ammPackageId: string
  readonly ammDefaultPools: string[]
  readonly exampleCoinPackageId: string
}

export const CONFIG: Config = {
  rpcUrl: 'https://fullnode.devnet.sui.io:443',

  ammPackageId: '0x88bbd38f27daaf1ac6ee362147865ca500da5d8',
  exampleCoinPackageId: '0xbe0a47f0dfca0699e8ed8d7e22d07d11004df4e6',

  ammDefaultPools: ['0x81de257f41e61e6bd70a3e9adf37f68fbcfc2e07'],
}
