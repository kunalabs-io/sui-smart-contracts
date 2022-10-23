import { useState, useEffect } from 'react'
import { getPoolBalances, getPoolCoinTypeArgs, getPools } from './lib/amm'
import { WalletStandardAdapterProvider } from '@mysten/wallet-adapter-all-wallets'
import { Coin, GetObjectDataResponse, JsonRpcProvider } from '@mysten/sui.js'
import { WalletProvider } from '@mysten/wallet-adapter-react'
import Box from '@mui/material/Box'
import { SwapAndCreatePool } from './components/Swap/SwapAndCreatePool'
import { CONFIG } from './lib/config'

const provider = new JsonRpcProvider(CONFIG.rpcUrl)
const wallet = new SuiWalletAdapter()
const supportedWallets = [
  // Add support for all wallets that adhere to the Wallet Standard:
  new WalletStandardAdapterProvider(),
]

const SUI_COIN_TYPE_ARG = '0x2::sui::SUI'
const EXAMPLE_COIN_TYPE_ARG = `${CONFIG.exampleCoinPackageId}::example_coin::EXAMPLE_COIN`

function App() {
  const [count, setCount] = useState(0)

  /* ============ wallet connection =========== */

  // const [walletConnected, setWalletConnected] = useState(wallet.connected)
  // const connect = useCallback(() => {
  //   if (wallet.connected || wallet.connecting) return

  //   wallet
  //     .connect()
  //     .then(() => {
  //       setWalletConnected(true)
  //     })
  //     .catch(console.error)
  // }, [])

  const [pools, setPools] = useState<GetObjectDataResponse[]>([])

  useEffect(() => {
    getPools(provider, wallet)
      .then(pools => setPools(pools.reverse()))
      .catch(console.error)
  }, [])

  const onPoolsChange = (newPools: GetObjectDataResponse[]) => {
    setPools(newPools)
  }

  console.log({ pools })
  /* =========== swap tab ========== */

  // first dropdown list
  // const uniqueCoinTypeArgs = getPoolsUniqueCoinTypeArgs(pools) // e.g. [0x2::sui::SUI, ...]
  // uniqueCoinTypeArgs.forEach(arg => {
  //   console.log(arg) // full type arg (e.g. `0x2::sui::SUI`)
  //   console.log(Coin.getCoinSymbol(arg)) // full type arg -> symbol (e.g. `SUI`)
  // })
  // const [firstCoinType, setFirstCoinType] = useState(SUI_COIN_TYPE_ARG)

  // second dropdown list
  // const possibleSecondCoinTypeArgs = getPossibleSecondCoinTypeArgs(pools, firstCoinType)

  // const [secondCoinType, setSecondCoinType] = useState<string>()
  // useEffect(() => {
  //   setSecondCoinType(EXAMPLE_COIN_TYPE_ARG) // user selects the second coin (one from possibleSecondCoinTypeArgs)
  // }, [])

  // selected pool
  // const [pool, setPool] = useState<GetObjectDataResponse>()
  // useEffect(() => {
  //   if (firstCoinType !== undefined && secondCoinType !== undefined) {
  //     setPool(selectPoolForPair(pools, [firstCoinType, secondCoinType]))
  //   }
  // }, [pools, firstCoinType, secondCoinType])

  // first input amounts
  // const [inputAmount, setInputAmount] = useState<bigint>()
  // useEffect(() => {
  //   setInputAmount(100n) // user sets amount via input
  // }, [])

  // calculate swap result (display on second form field)
  const [outputAmount, setOutputAmount] = useState<bigint>()
  // useEffect(() => {
  //   if (pool === undefined || inputAmount === undefined) {
  //     return
  //   }
  //   setOutputAmount(calcSwapAmountOut(pool, firstCoinType, inputAmount))
  // }, [pool, firstCoinType, inputAmount])

  // on swap
  // const onSwap = useCallback(async () => {
  // if (secondCoinType === undefined || inputAmount === undefined || pool == undefined) {
  //   return
  // }
  // await swap(provider, wallet, pool, firstCoinType, inputAmount, 0)
  // }, [pool, firstCoinType, secondCoinType, inputAmount])

  /* =========== create pool tab ========== */

  // const [userCoins, setUserCoins] = useState<GetObjectDataResponse[]>([])
  // useEffect(() => {
  //   getUserCoins(provider, wallet).then(setUserCoins).catch(console.error)
  // }, [])

  // use this list for the dropdowns on the first and second input on the create pool tab
  // const userUniqueCoinTypes = getUniqueCoinTypes(userCoins)

  // useEffect(() => {
  //   setFirstCoinType(SUI_COIN_TYPE_ARG) // user selects first coin
  //   setSecondCoinType(EXAMPLE_COIN_TYPE_ARG) // user selects second coin
  // }, [])

  // const onCreatePool = useCallback(async () => {
  //   if (firstCoinType === undefined || secondCoinType === undefined) {
  //     return
  //   }

  //   await createPool(provider, wallet, {
  //     typeA: firstCoinType,
  //     initAmountA: 10_000n, // make it based on amount input field
  //     typeB: secondCoinType,
  //     initAmountB: 10_000n, // make it based on amount input field
  //     lpFeeBps: 30,
  //     adminFeePct: 10,
  //   })

  //   // update pool list
  //   setPools(await getPools(provider))
  // }, [firstCoinType, secondCoinType])

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

  /* =========== Pool List section ========== */

  // display a list of pools with their info
  pools.forEach(pool => {
    const [coinTypeA, coinTypeB] = getPoolCoinTypeArgs(pool)
    const symbolA = Coin.getCoinSymbol(coinTypeA)
    const symbolB = Coin.getCoinSymbol(coinTypeB)
    const [balanceA, balanceB, lpSupply] = getPoolBalances(pool)

    // display this on UI
    console.log(`${symbolA}-${symbolB}`)
    console.log(`${symbolA} balance: ${balanceA}`)
    console.log(`${symbolB} balance: ${balanceB}`)
    console.log(`LP supply: ${lpSupply}`)
  })

  // const onDeposit = useCallback(async () => {
  //   const pool = pools[0] // (hard coded - make it based on button click)
  //   if (pool === undefined) return

  //   const [coinTypeA, coinTypeB] = getPoolCoinTypeArgs(pool)

  //   const amountA = 1000n // hard coded - make it based on input
  //   const amountB = calcPoolOtherDepositAmount(pool, amountA, coinTypeA) // display this on the second input (disabled)

  //   await deposit(provider, wallet, pool, amountA, amountB, 0)
  // }, [pools])

  return (
    <Box display="flex" justifyContent="center">
      <WalletProvider adapters={supportedWallets}>
        <SwapAndCreatePool pools={pools} provider={provider} onPoolsChange={onPoolsChange} />
      </WalletProvider>
    </Box>
  )
}

export default App
