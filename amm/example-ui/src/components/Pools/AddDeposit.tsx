import { ChangeEvent, useEffect, useState } from 'react'
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline'
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormHelperText,
  IconButton,
  TextField,
} from '@mui/material/'
import { JsonRpcProvider } from '@mysten/sui.js'
import CloseIcon from '@mui/icons-material/Close'
import { useWallet } from '@mysten/wallet-adapter-react'

import { ONLY_NUMBERS_REGEX } from '../../utils/regex'
import { isSubmitFormDisabled } from '../../utils/checkSubmittingForm'
import { Pool } from '../../lib/amm-sdk/pool'
import { getCoinBalances, getUserCoins } from '../../lib/amm-sdk/framework/coin'
import { CONFIG } from '../../lib/config'

interface Props {
  isOpen: boolean
  onClose: () => void
  pool: Pool
  provider: JsonRpcProvider
  getUpdatedPools: () => void
  showSuccessSnackbar: () => void
  showErrorSnackbar: () => void
}

export const AddDeposit = ({
  isOpen,
  onClose,
  pool,
  provider,
  getUpdatedPools,
  showSuccessSnackbar,
  showErrorSnackbar,
}: Props) => {
  const [firstCoinValue, setFirstCoinValue] = useState('')
  const [secondCoinValue, setSecondCoinValue] = useState('')
  const [coinBalances, setCoinBalances] = useState<Map<string, bigint>>()

  const { wallet, connected } = useWallet()

  useEffect(() => {
    if (!wallet || !connected) {
      return
    }
    getUserCoins(provider, wallet)
      .then(coins => {
        setCoinBalances(getCoinBalances(coins))
      })
      .catch(console.error)
  }, [wallet, provider, connected])

  const [symbolA, symbolB] = pool.coinMetadata.map(m => m.symbol)

  const isEmptyPool = pool.state.balanceA.value === 0n || pool.state.balanceB.value === 0n

  const handleFirstCoinValueChange = (event: ChangeEvent<HTMLInputElement>) => {
    const newFirstCoinValue = event.target.value
    if (newFirstCoinValue === '' || ONLY_NUMBERS_REGEX.test(newFirstCoinValue)) {
      setFirstCoinValue(newFirstCoinValue)
      if (!isEmptyPool) {
        const amount = pool.coinMetadata[0].newAmount(BigInt(newFirstCoinValue))
        setSecondCoinValue(pool.calcDepositOtherAmount(pool.state.typeArgs[0], amount)[0].int.toString())
      }
    }
  }

  const handleSecondCoinValueChange = (event: ChangeEvent<HTMLInputElement>) => {
    const newSecondCoinValue = event.target.value
    if (newSecondCoinValue === '' || ONLY_NUMBERS_REGEX.test(newSecondCoinValue)) {
      setSecondCoinValue(newSecondCoinValue)
    }
  }

  const onDeposit = async () => {
    if (!wallet || !connected) {
      return
    }
    try {
      const amountA = BigInt(firstCoinValue)
      const amountB = BigInt(secondCoinValue)

      await pool.deposit(provider, wallet, {
        amountA,
        amountB,
        maxSlippagePct: CONFIG.defaultSlippagePct,
      })

      getUpdatedPools()
      onClose()
      showSuccessSnackbar()
    } catch (e) {
      console.error(e)
      showErrorSnackbar()
    }
  }

  const [coinTypeA, coinTypeB] = pool.state.typeArgs

  return (
    <Dialog
      onClose={onClose}
      aria-labelledby="customized-dialog-title"
      open={isOpen}
      PaperProps={{ sx: { width: 500 } }}
    >
      <DialogTitle sx={{ m: 0, p: 2 }}>
        Add Deposit
        {onClose ? (
          <IconButton
            aria-label="close"
            onClick={onClose}
            sx={{
              position: 'absolute',
              right: 8,
              top: 8,
            }}
          >
            <CloseIcon />
          </IconButton>
        ) : null}
      </DialogTitle>
      <DialogContent dividers>
        <Box>
          <Box sx={{ display: 'flex' }}>
            <TextField
              value={firstCoinValue}
              onChange={handleFirstCoinValueChange}
              label="Input"
              variant="outlined"
              fullWidth
            />
            <TextField label="Token" value={symbolA} sx={{ width: 150 }} disabled />
          </Box>
          <FormHelperText sx={{ position: 'absolute' }}>
            {coinBalances && coinBalances.get(coinTypeA) ? `Max: ${coinBalances.get(coinTypeA)?.toString()}` : 'Max: 0'}
          </FormHelperText>
          <Box p={2} textAlign="center">
            <AddCircleOutlineIcon
              fontSize="large"
              sx={theme => ({
                fill: theme.palette.primary.main,
              })}
            />
          </Box>
        </Box>
        <Box sx={{ display: 'flex' }}>
          <TextField
            value={secondCoinValue}
            sx={{ display: 'block' }}
            label="Input"
            variant="outlined"
            fullWidth
            onChange={handleSecondCoinValueChange}
            disabled={!isEmptyPool}
          />
          <TextField label="Token" value={symbolB} sx={{ width: 150 }} disabled />
        </Box>
        <FormHelperText sx={{ position: 'absolute' }}>
          {coinBalances && coinBalances.get(coinTypeB) ? `Max: ${coinBalances.get(coinTypeB)?.toString()}` : 'Max: 0'}
        </FormHelperText>
        <Box height={32} />
      </DialogContent>
      <DialogActions>
        <Button
          autoFocus
          onClick={onDeposit}
          fullWidth
          variant="contained"
          disabled={isSubmitFormDisabled({
            firstCoinType: coinTypeA,
            firstCoinValue,
            secondCoinType: coinTypeB,
            secondCoinValue,
            coinBalances,
          })}
        >
          Deposit
        </Button>
      </DialogActions>
    </Dialog>
  )
}
