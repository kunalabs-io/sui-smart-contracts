import { useState, useEffect, useCallback } from 'react'
import { WalletStandardAdapterProvider } from '@mysten/wallet-adapter-all-wallets'
import { GetObjectDataResponse, JsonRpcProvider } from '@mysten/sui.js'
import { WalletProvider } from '@mysten/wallet-adapter-react'
import { Box, IconButton, Typography } from '@mui/material'
import TwitterIcon from '@mui/icons-material/Twitter'
import GitHubIcon from '@mui/icons-material/GitHub'

import { getPools } from './lib/amm'
import { SwapAndCreatePool } from './components/SwapAndCreatePool/SwapAndCreatePool'
import { Pools } from './components/Pools/Pools'
import { MyLPPositions } from './components/MyLPPositions/MyLPPositions'
import { CONFIG } from './lib/config'

const supportedWallets = [new WalletStandardAdapterProvider()]
const provider = new JsonRpcProvider(CONFIG.rpcUrl)

function App() {
  const [count, setCount] = useState(0)

  const [pools, setPools] = useState<GetObjectDataResponse[]>([])

  useEffect(() => {
    getPools(provider, wallet)
      .then(pools => setPools(pools.reverse()))
      .catch(console.error)
  }, [count])

  const getUpdatedPools = useCallback(() => {
    setCount(count => count + 1)
  }, [])

  return (
    <Box>
      <Box display="flex" justifyContent="center" alignItems="center">
        <Typography variant="h4" mr={2}>
          Kuna Labs
        </Typography>
        <IconButton
          sx={{ color: '#1DA1F2' }}
          component="a"
          href="https://twitter.com/kuna_labs"
          target="_blank"
          rel="noopener noreferrer"
        >
          <TwitterIcon sx={{ width: 32, height: 32 }} />
        </IconButton>
        <IconButton
          component="a"
          href="https://github.com/kunalabs-io/sui-smart-contracts/tree/master/amm"
          target="_blank"
          rel="noopener noreferrer"
        >
          <GitHubIcon sx={{ width: 32, height: 32 }} />
        </IconButton>
      </Box>
      <WalletProvider adapters={supportedWallets}>
        <SwapAndCreatePool pools={pools} provider={provider} getUpdatedPools={getUpdatedPools} count={count} />
        <MyLPPositions pools={pools} provider={provider} count={count} getUpdatedPools={getUpdatedPools} />
        <Pools pools={pools} provider={provider} getUpdatedPools={getUpdatedPools} />
      </WalletProvider>
    </Box>
  )
}

export default App
