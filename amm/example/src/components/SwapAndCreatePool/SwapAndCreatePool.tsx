import { useState, ChangeEvent, useEffect } from 'react'
import Tabs from '@mui/material/Tabs'
import Tab from '@mui/material/Tab'
import { Alert, Box, FormHelperText, Snackbar } from '@mui/material'
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
  getPoolsUniqueCoinTypeArgs,
  getPossibleSecondCoinTypeArgs,
  selectPoolForPair,
  swap,
} from '../../lib/amm'
import { ConnectWalletModal } from '../Wallet/ConnectWalletModal'
import { getCoinBalances, getUniqueCoinTypes, getUserCoins } from '../../lib/coin'
import { ONLY_NUMBERS_REGEX } from '../../utils/regex'
import { isSubmitFormDisabled } from '../../utils/checkSubmittingForm'

interface Props {
  pools: GetObjectDataResponse[]
  provider: JsonRpcProvider
  getUpdatedPools: () => void
  count: number
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

export const SwapAndCreatePool = ({ pools, provider, getUpdatedPools, count }: Props) => {
  const [tabValue, setTabValue] = useState(TabValue.Swap)
  const [errorSnackbar, setErrorSnackbar] = useState({ open: false, message: '' })
  const [successSnackbar, setSuccessSnackbar] = useState({ open: false, message: '' })

  const { wallet, connected } = useWallet()
  // Swap first coin options
  const [firstCoinOptions, setFirstCoinOptions] = useState<CoinTypeOption[]>([
    { value: SUI_COIN_TYPE_ARG, label: 'SUI' },
  ])
  // Swap second coin options
  const [secondCoinOptions, setSecondCoinOptions] = useState<CoinTypeOption[]>([])
  const [firstCoinType, setFirstCoinType] = useState(SUI_COIN_TYPE_ARG)
  const [secondCoinType, setSecondCoinType] = useState('')
  const [firstCoinValue, setFirstCoinValue] = useState('')
  const [secondCoinValue, setSecondCoinValue] = useState('')

  const [pool, setPool] = useState<GetObjectDataResponse>()
  const [coinBalances, setCoinBalances] = useState<Map<string, bigint>>()
  const [userCoins, setUserCoins] = useState<CoinTypeOption[]>([])

  // create pool tab user coins
  useEffect(() => {
    if (!wallet || !connected) {
      return
    }
    getUserCoins(provider, wallet)
      .then(coins => {
        const newCoins = getUniqueCoinTypes(coins).map(arg => ({ value: arg, label: Coin.getCoinSymbol(arg) }))
        setUserCoins(newCoins)
        setCoinBalances(getCoinBalances(coins))
      })
      .catch(console.error)
  }, [provider, wallet, connected, count])

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

    if (newFirstCoinValue === '' || ONLY_NUMBERS_REGEX.test(newFirstCoinValue)) {
      setFirstCoinValue(newFirstCoinValue)
      if (pool === undefined || tabValue === TabValue.CreatePool) {
        return
      }
      setSecondCoinValue(calcSwapAmountOut(pool, firstCoinType, BigInt(newFirstCoinValue)).toString())
    }
  }

  const handleSecondCoinValueChange = (event: ChangeEvent<HTMLInputElement>) => {
    if (event.target.value === '' || ONLY_NUMBERS_REGEX.test(event.target.value)) {
      setSecondCoinValue(event.target.value)
    }
  }

  const handleSnackbarClose = () => {
    setErrorSnackbar({ open: false, message: '' })
    setSuccessSnackbar({ open: false, message: '' })
  }

  const onSwap = async () => {
    if (!wallet || !connected) {
      return
    }
    if (!secondCoinType || !firstCoinValue || !pool) {
      return
    }

    try {
      await swap(provider, wallet, pool, firstCoinType, BigInt(firstCoinValue), 1)
      resetValues()
      getUpdatedPools()
      setSuccessSnackbar({ open: true, message: 'Swap Success' })
    } catch (e) {
      console.error(e)
      setErrorSnackbar({ open: true, message: 'Swap Error' })
    }
  }

  const onCreatePool = async () => {
    if (!firstCoinType || !secondCoinType || !wallet || !connected) {
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

      getUpdatedPools()
      resetValues()
      setSuccessSnackbar({ open: true, message: 'Create Pool Success' })
    } catch (e) {
      console.error(e)
      setErrorSnackbar({ open: true, message: 'Create Pool Error' })
    }
  }

  const resetValues = () => {
    setFirstCoinType(SUI_COIN_TYPE_ARG)
    setSecondCoinType('')
    setFirstCoinValue('')
    setSecondCoinValue('')
    handleSnackbarClose()
  }

  const handleTabChange = (_e: React.SyntheticEvent, newValue: TabValue) => {
    setTabValue(newValue)
    resetValues()
  }

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
        <FormHelperText sx={{ position: 'absolute' }}>
          {coinBalances && coinBalances.get(firstCoinType)
            ? `Max: ${coinBalances.get(firstCoinType)?.toString()}`
            : 'Max: 0'}
        </FormHelperText>

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

        <Box sx={{ display: 'flex' }}>
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
        <FormHelperText sx={{ position: 'absolute' }}>
          {coinBalances && secondCoinType && coinBalances.get(secondCoinType)
            ? `Max: ${coinBalances.get(secondCoinType)?.toString()}`
            : 'Max: 0'}
        </FormHelperText>
        <Box height={48} />
        <Box>
          {connected && wallet ? (
            <Button
              color="primary"
              fullWidth
              variant="contained"
              onClick={tabValue === TabValue.Swap ? onSwap : onCreatePool}
              disabled={isSubmitFormDisabled({
                firstCoinType,
                firstCoinValue,
                secondCoinType,
                secondCoinValue,
                coinBalances,
              })}
            >
              {tabValue === TabValue.Swap ? 'Swap' : 'Create pool'}
            </Button>
          ) : (
            <ConnectWalletModal />
          )}
        </Box>
      </Box>
      <Snackbar
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        open={successSnackbar.open}
        onClose={handleSnackbarClose}
        autoHideDuration={4000}
      >
        <Alert elevation={6} variant="filled" severity="success" sx={{ width: '200px' }}>
          {successSnackbar.message}
        </Alert>
      </Snackbar>
      <Snackbar
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        open={errorSnackbar.open}
        onClose={handleSnackbarClose}
        autoHideDuration={4000}
      >
        <Alert elevation={6} variant="filled" severity="error" sx={{ width: '200px' }}>
          {errorSnackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  )
}
