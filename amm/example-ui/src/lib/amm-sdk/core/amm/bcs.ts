import { BCS, getSuiMoveConfig } from '@mysten/bcs'
import { PACKAGE_ID } from '..'

export const bcs = new BCS(getSuiMoveConfig())

bcs.registerStructType(`${PACKAGE_ID}::amm::PoolCreationEvent`, { pool_id: 'address' })
