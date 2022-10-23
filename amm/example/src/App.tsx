import { useState, useEffect, useCallback } from 'react'
import { WalletStandardAdapterProvider } from '@mysten/wallet-adapter-all-wallets'
import { GetObjectDataResponse, JsonRpcProvider } from '@mysten/sui.js'
import { WalletProvider } from '@mysten/wallet-adapter-react'
import { Box, Divider } from '@mui/material'

import { getPools } from './lib/amm'
import { SwapAndCreatePool } from './components/Swap/SwapAndCreatePool'
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

  const onPoolsChange = (newPools: GetObjectDataResponse[]) => {
    setPools(newPools)
  }

  const getUpdatedPools = useCallback(() => {
    setCount(count => count + 1)
  }, [])

  /* =========== My LP Positions section ========== */

  // const [userLpCoins, setUserLpCoins] = useState<GetObjectDataResponse[]>([])
  // useEffect(() => {
  //   getUserLpCoins(provider, wallet).then(setUserLpCoins).catch(console.error)
  // }, [])

  // list positions (each lpCoin represents a position)
  // userLpCoins.forEach(lpCoin => {
  //   const [coinTypeA, coinTypeB] = getLpCoinTypeArgs(lpCoin)
  //   const symbolA = Coin.getCoinSymbol(coinTypeA)
  //   const symbolB = Coin.getCoinSymbol(coinTypeB)
  //   const lpAmount = getLpCoinBalance(lpCoin)

  //   // find pool corresponding to the lp coin
  //   const lpCoinPoolId = getLpCoinPoolId(lpCoin)
  //   const pool = pools.find(pool => getObjectId(pool) === lpCoinPoolId)
  //   if (pool === undefined) return

  //   const [amountA, amountB] = calcPoolLpValue(pool, lpAmount)

  //   // display this on UI
  //   console.log(`LP amount: ${lpAmount}`)
  //   console.log(`${symbolA} value: ${amountA}`)
  //   console.log(`${symbolB} value: ${amountB}`)
  // })

  // const onWithdraw = useCallback(async () => {
  //   const lpCoin = userLpCoins[0] // (hard coded - make it based on button click)
  //   await withdraw(provider, wallet, lpCoin, 0)

  //   // update position list
  //   getUserLpCoins(provider, wallet).then(setUserLpCoins).catch(console.error)
  // }, [userLpCoins])

  return (
    <Box>
      <WalletProvider adapters={supportedWallets}>
        <SwapAndCreatePool
          pools={pools}
          provider={provider}
          onPoolsChange={onPoolsChange}
          getUpdatedPools={getUpdatedPools}
        />
        <Divider color="black" />
        <MyLPPositions pools={pools} provider={provider} />
        <Divider color="black" />
        <Pools pools={pools} provider={provider} getUpdatedPools={getUpdatedPools} />
      </WalletProvider>
    </Box>
  )
}

export default App
