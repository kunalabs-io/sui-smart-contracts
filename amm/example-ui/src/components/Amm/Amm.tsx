import { useState, useEffect, useCallback } from 'react'
import { GetObjectDataResponse, JsonRpcProvider } from '@mysten/sui.js'
import { useWallet } from '@mysten/wallet-adapter-react'
import { Box } from '@mui/material'

import { getPools } from '../../lib/amm'
import { SwapAndCreatePool } from '../SwapAndCreatePool/SwapAndCreatePool'
import { MyLPPositions } from '../MyLPPositions/MyLPPositions'
import { Pools } from '../Pools/Pools'
import { CONFIG } from '../../lib/config'

const provider = new JsonRpcProvider(CONFIG.rpcUrl)

export const Amm = () => {
  const { wallet, connected } = useWallet()

  const [count, setCount] = useState(0)

  const [pools, setPools] = useState<GetObjectDataResponse[]>([])

  useEffect(() => {
    if (!wallet || !connected) {
      return
    }
    getPools(provider).then(setPools).catch(console.error)
  }, [count, wallet, connected])

  const getUpdatedPools = useCallback(() => {
    setCount(count => count + 1)
  }, [])

  return (
    <Box>
      <SwapAndCreatePool pools={pools} provider={provider} getUpdatedPools={getUpdatedPools} count={count} />
      <MyLPPositions pools={pools} provider={provider} count={count} getUpdatedPools={getUpdatedPools} />
      <Pools pools={pools} provider={provider} getUpdatedPools={getUpdatedPools} />
    </Box>
  )
}
