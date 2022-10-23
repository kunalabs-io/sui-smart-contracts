import { ChangeEvent, useState } from 'react'
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline'
import { Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, IconButton, TextField } from '@mui/material/'
import { Coin, GetObjectDataResponse, JsonRpcProvider } from '@mysten/sui.js'
import CloseIcon from '@mui/icons-material/Close'
import { useWallet } from '@mysten/wallet-adapter-react'

import { calcPoolOtherDepositAmount, deposit, getPoolCoinTypeArgs } from '../../lib/amm'

interface Props {
  isOpen: boolean
  onClose: () => void
  pool: GetObjectDataResponse
  provider: JsonRpcProvider
  getUpdatedPools: () => void
}

export const AddDeposit = ({ isOpen, onClose, pool, provider, getUpdatedPools }: Props) => {
  const [firstCoinValue, setFirstCoinValue] = useState('')
  const [secondCoinValue, setSecondCoinValue] = useState('')

  const [coinTypeA, coinTypeB] = getPoolCoinTypeArgs(pool)
  const symbolA = Coin.getCoinSymbol(coinTypeA)
  const symbolB = Coin.getCoinSymbol(coinTypeB)

  const { wallet } = useWallet()

  const handleFirstCoinValueChange = (event: ChangeEvent<HTMLInputElement>) => {
    const newFirstCoinValue = event.target.value
    setFirstCoinValue(newFirstCoinValue)
    setSecondCoinValue(calcPoolOtherDepositAmount(pool, BigInt(newFirstCoinValue), coinTypeA).toString())
  }

  const onDeposit = async () => {
    if (wallet) {
      try {
        const amountA = BigInt(firstCoinValue)
        const amountB = calcPoolOtherDepositAmount(pool, amountA, coinTypeA)

        await deposit(provider, wallet, pool, amountA, amountB, 0)
        getUpdatedPools()
        onClose()
      } catch (e) {
        console.error(e)
      }
    }
  }

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
          <Box p={2} textAlign="center">
            <AddCircleOutlineIcon
              fontSize="large"
              sx={theme => ({
                fill: theme.palette.primary.main,
              })}
            />
          </Box>
        </Box>
        <Box sx={{ display: 'flex', mb: 4 }}>
          <TextField
            value={secondCoinValue}
            sx={{ display: 'block' }}
            label="Input"
            variant="outlined"
            fullWidth
            disabled
          />
          <TextField label="Token" value={symbolB} sx={{ width: 150 }} disabled />
        </Box>
      </DialogContent>
      <DialogActions>
        <Button autoFocus onClick={onDeposit} fullWidth variant="contained">
          Deposit
        </Button>
      </DialogActions>
    </Dialog>
  )
}
