import { useState, ChangeEvent, useEffect } from 'react'
import Tabs from '@mui/material/Tabs'
import Tab from '@mui/material/Tab'
import { Box } from '@mui/material'
import TextField from '@mui/material/TextField'
import MenuItem from '@mui/material/MenuItem'
import ArrowDownwardIcon from '@mui/icons-material/ArrowDownward'
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline'
import Button from '@mui/material/Button'
import { Coin, GetObjectDataResponse, JsonRpcProvider } from '@mysten/sui.js'
import { useWallet } from '@mysten/wallet-adapter-react'

import {
  calcSwapAmountOut,
  createPool,
  getPools,
  getPoolsUniqueCoinTypeArgs,
  getPossibleSecondCoinTypeArgs,
  selectPoolForPair,
  swap,
} from '../../lib/amm'
import { ConnectWalletModal } from '../Wallet/ConnectWalletModal'
import { getUniqueCoinTypes, getUserCoins } from '../../lib/coin'

interface Props {
  pools: GetObjectDataResponse[]
  provider: JsonRpcProvider
  onPoolsChange: (newPools: GetObjectDataResponse[]) => void
  getUpdatedPools: () => void
}

interface CoinTypeOption {
  value: string
  label: string
}

const SUI_COIN_TYPE_ARG = '0x2::sui::SUI'

enum TabValue {
  Swap = 0,
  CreatePool = 1,
}

export const SwapAndCreatePool = ({ pools, provider, onPoolsChange, getUpdatedPools }: Props) => {
  const [tabValue, setTabValue] = useState(TabValue.Swap)

  const { wallet, connected } = useWallet()
  // Swap first coin options
  const [firstCoinOptions, setFirstCoinOptions] = useState<CoinTypeOption[]>([])
  // Swap second coin options
  const [secondCoinOptions, setSecondCoinOptions] = useState<CoinTypeOption[]>([])
  const [firstCoinType, setFirstCoinType] = useState(SUI_COIN_TYPE_ARG)
  const [secondCoinType, setSecondCoinType] = useState('')
  const [firstCoinValue, setFirstCoinValue] = useState('')
  const [secondCoinValue, setSecondCoinValue] = useState('')

  const [pool, setPool] = useState<GetObjectDataResponse>()

  // create pool tab user coins
  const [userCoins, setUserCoins] = useState<CoinTypeOption[]>([])

  useEffect(() => {
    if (wallet) {
      getUserCoins(provider, wallet)
        .then(coins => {
          const newCoins = getUniqueCoinTypes(coins).map(arg => ({ value: arg, label: Coin.getCoinSymbol(arg) }))
          setUserCoins(newCoins)
        })
        .catch(console.error)
    }
  }, [provider, wallet])

  useEffect(() => {
    if (firstCoinType && secondCoinType) {
      setPool(selectPoolForPair(pools, [firstCoinType, secondCoinType]))
    }
  }, [pools, firstCoinType, secondCoinType])

  useEffect(() => {
    if (pools.length) {
      // First dropdown list
      const uniqueCoinTypeArgs = getPoolsUniqueCoinTypeArgs(pools)
      const initialCoinOptions = uniqueCoinTypeArgs.map(arg => ({ value: arg, label: Coin.getCoinSymbol(arg) }))
      setFirstCoinOptions(initialCoinOptions)

      // Second dropdown list
      const possibleSecondCoinTypeArgs = getPossibleSecondCoinTypeArgs(pools, SUI_COIN_TYPE_ARG)
      const newSecondCoinOptions = possibleSecondCoinTypeArgs.map(arg => ({
        value: arg,
        label: Coin.getCoinSymbol(arg),
      }))
      setSecondCoinOptions(newSecondCoinOptions)
    }
  }, [pools])

  const handleFirstCoinTypeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newFirstCoinType = event.target.value
    setFirstCoinType(newFirstCoinType)
    const possibleSecondCoinTypeArgs = getPossibleSecondCoinTypeArgs(pools, newFirstCoinType)
    const newSecondCoinOptions = possibleSecondCoinTypeArgs.map(arg => ({ value: arg, label: Coin.getCoinSymbol(arg) }))
    setSecondCoinOptions(newSecondCoinOptions)
    setSecondCoinType('')
  }

  const handleSecondCoinTypeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSecondCoinType(event.target.value)
  }

  const handleFirstCoinValueChange = (event: ChangeEvent<HTMLInputElement>) => {
    const newFirstCoinValue = event.target.value
    setFirstCoinValue(newFirstCoinValue)
    if (pool === undefined || tabValue === TabValue.CreatePool) {
      return
    }
    setSecondCoinValue(calcSwapAmountOut(pool, firstCoinType, BigInt(newFirstCoinValue)).toString())
  }

  const handleSecondCoinValueChange = (event: ChangeEvent<HTMLInputElement>) => {
    setSecondCoinValue(event.target.value)
  }

  const onSwap = async () => {
    if (wallet) {
      if (!secondCoinType || !firstCoinValue || !pool) {
        return
      }
      await swap(provider, wallet, pool, firstCoinType, BigInt(firstCoinValue), 0)
      resetValues()
      getUpdatedPools()
    }
  }

  const onCreatePool = async () => {
    if (!firstCoinType || !secondCoinType || !wallet) {
      return
    }

    try {
      await createPool(provider, wallet, {
        typeA: firstCoinType,
        initAmountA: BigInt(firstCoinValue),
        typeB: secondCoinType,
        initAmountB: BigInt(secondCoinValue),
        lpFeeBps: 30,
        adminFeePct: 10,
      })

      // update pool list
      onPoolsChange(await getPools(provider))
      resetValues()
    } catch (e) {
      console.error(e)
    }
  }

  const resetValues = () => {
    setFirstCoinType(SUI_COIN_TYPE_ARG)
    setSecondCoinType('')
    setFirstCoinValue('')
    setSecondCoinValue('')
  }

  const handleTabChange = (_e: React.SyntheticEvent, newValue: TabValue) => {
    setTabValue(newValue)
    resetValues()
  }

  const submitDisabled =
    !firstCoinValue || !secondCoinValue || !firstCoinType || !secondCoinType || firstCoinType === secondCoinType

  return (
    <Box
      sx={{ width: 500, boxShadow: '0px 5px 10px 0px rgba(0, 0, 0, 0.5)', borderRadius: '16px;', my: 3, mx: 'auto' }}
    >
      <Box sx={{ borderBottom: 1, borderColor: 'black' }}>
        <Tabs value={tabValue} onChange={handleTabChange} centered variant="fullWidth">
          <Tab label="Swap" />
          <Tab label="Create Pool" />
        </Tabs>
      </Box>
      <Box sx={{ p: 4 }}>
        <Box sx={{ display: 'flex' }}>
          <TextField
            value={firstCoinValue}
            onChange={handleFirstCoinValueChange}
            label="Input"
            variant="outlined"
            fullWidth
          />
          <TextField
            select
            label="Token"
            value={firstCoinType}
            onChange={handleFirstCoinTypeChange}
            sx={{ width: 150 }}
          >
            {tabValue === TabValue.Swap
              ? firstCoinOptions.map(option => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
                  </MenuItem>
                ))
              : userCoins.map(option => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
                  </MenuItem>
                ))}
          </TextField>
        </Box>

        <Box p={2} textAlign="center">
          {tabValue === TabValue.Swap ? (
            <ArrowDownwardIcon
              fontSize="large"
              sx={theme => ({
                fill: theme.palette.primary.main,
              })}
            />
          ) : (
            <AddCircleOutlineIcon
              fontSize="large"
              sx={theme => ({
                fill: theme.palette.primary.main,
              })}
            />
          )}
        </Box>

        <Box sx={{ display: 'flex', mb: 4 }}>
          <TextField
            value={secondCoinValue}
            sx={{ display: 'block' }}
            label="Input"
            variant="outlined"
            fullWidth
            onChange={handleSecondCoinValueChange}
            disabled={tabValue === TabValue.Swap}
          />
          <TextField
            select
            label="Token"
            value={secondCoinType || ''}
            sx={{ width: 150 }}
            onChange={handleSecondCoinTypeChange}
          >
            {tabValue === TabValue.Swap
              ? secondCoinOptions.map(option => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
                  </MenuItem>
                ))
              : userCoins.map(option => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
                  </MenuItem>
                ))}
          </TextField>
        </Box>
        <Box>
          {connected && wallet ? (
            <Button
              color="primary"
              fullWidth
              variant="contained"
              onClick={tabValue === TabValue.Swap ? onSwap : onCreatePool}
              disabled={submitDisabled}
            >
              {tabValue === TabValue.Swap ? 'Swap' : 'Add liquidity '}
            </Button>
          ) : (
            <ConnectWalletModal />
          )}
        </Box>
      </Box>
    </Box>
  )
}
