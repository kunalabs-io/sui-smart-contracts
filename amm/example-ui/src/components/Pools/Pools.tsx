import { useState } from 'react'
import { Accordion, AccordionDetails, AccordionSummary, Alert, Box, Snackbar } from '@mui/material'
import { Typography } from '@mui/material'
import ExpandMoreIcon from '@mui/icons-material/ExpandMore'
import Button from '@mui/material/Button'
import { Coin, GetObjectDataResponse, getObjectId, JsonRpcProvider } from '@mysten/sui.js'
import { useWallet } from '@mysten/wallet-adapter-react'

import { getPoolBalances, getPoolCoinTypeArgs } from '../../lib/amm'
import { AddDeposit } from './AddDeposit'
import { ConnectWalletModal } from '../Wallet/ConnectWalletModal'
import { ellipsizeAddress } from '../../lib/util'

interface Props {
  pools: GetObjectDataResponse[]
  provider: JsonRpcProvider
  getUpdatedPools: () => void
}

export const Pools = ({ pools, provider, getUpdatedPools }: Props) => {
  const { wallet, connected } = useWallet()

  const [errorSnackbar, setErrorSnackbar] = useState({ open: false, message: '' })
  const [successSnackbar, setSuccessSnackbar] = useState({ open: false, message: '' })
  const [expanded, setExpanded] = useState(true)

  const [isOpenAddDeposit, setIsOpenAddDeposit] = useState(false)
  const [activePool, setActivePool] = useState<GetObjectDataResponse>()

  const handleAddDepositClick = (pool: GetObjectDataResponse) => {
    setActivePool(pool)
    setIsOpenAddDeposit(true)
  }

  const handleCloseAddDepositModal = () => {
    setActivePool(undefined)
    setIsOpenAddDeposit(false)
  }

  const handleChange = (_event: React.SyntheticEvent, newExpanded: boolean) => {
    setExpanded(newExpanded)
  }

  const handleSnackbarClose = () => {
    setErrorSnackbar({ open: false, message: '' })
    setSuccessSnackbar({ open: false, message: '' })
  }

  const showSuccessSnackbar = () => {
    setSuccessSnackbar({ open: true, message: 'Add Deposit Success' })
  }

  const showErrorSnackbar = () => {
    setErrorSnackbar({ open: true, message: 'Add Deposit Error' })
  }

  if (!pools.length) {
    return (
      <Box sx={{ mx: 'auto', width: 500, mt: 3 }}>
        <Typography variant="h5" sx={{ mb: 2 }}>
          Pool List
        </Typography>
        <Typography variant="body1">List is empty</Typography>
      </Box>
    )
  }

  return (
    <Box sx={{ mx: 'auto', width: 532, mt: 3 }}>
      <Accordion expanded={expanded} onChange={handleChange} elevation={0}>
        <AccordionSummary expandIcon={<ExpandMoreIcon />} aria-controls="panel1a-content" id="panel1a-header">
          <Typography variant="h5">Pool List</Typography>
        </AccordionSummary>
        <AccordionDetails>
          {pools.map(pool => {
            const [coinTypeA, coinTypeB] = getPoolCoinTypeArgs(pool)
            const symbolA = Coin.getCoinSymbol(coinTypeA)
            const symbolB = Coin.getCoinSymbol(coinTypeB)
            const [balanceA, balanceB, lpSupply] = getPoolBalances(pool)
            const poolId = getObjectId(pool)
            return (
              <Box
                key={`${poolId}`}
                sx={{ boxShadow: '0px 5px 10px 0px rgba(0, 0, 0, 0.5)', borderRadius: '16px;', p: 3, mb: 3 }}
              >
                <Typography variant="body1" color="primary">
                  {symbolA}&nbsp;<span style={{ color: '#46505A' }}>-</span>&nbsp;{symbolB}&nbsp;
                  <Typography
                    component="a"
                    color="primary"
                    href={`https://explorer.devnet.sui.io/objects/${poolId}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    variant="body2"
                  >
                    {`(${ellipsizeAddress(poolId)})`}
                  </Typography>
                </Typography>
                <Typography variant="body2">{`${symbolA} balance: ${balanceA}`}</Typography>
                <Typography variant="body2">{`${symbolB} balance: ${balanceB}`}</Typography>
                <Typography variant="body2">{`LP supply: ${lpSupply}`}</Typography>

                {connected && wallet ? (
                  <Button
                    color="primary"
                    fullWidth
                    variant="contained"
                    sx={{ mt: 3 }}
                    onClick={() => handleAddDepositClick(pool)}
                  >
                    Deposit
                  </Button>
                ) : (
                  <ConnectWalletModal />
                )}
              </Box>
            )
          })}
        </AccordionDetails>
      </Accordion>
      {activePool && (
        <AddDeposit
          isOpen={isOpenAddDeposit}
          onClose={handleCloseAddDepositModal}
          pool={activePool}
          provider={provider}
          getUpdatedPools={getUpdatedPools}
          showSuccessSnackbar={showSuccessSnackbar}
          showErrorSnackbar={showErrorSnackbar}
        />
      )}
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
