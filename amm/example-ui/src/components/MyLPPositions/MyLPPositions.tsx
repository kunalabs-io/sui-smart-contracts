import { useEffect, useState } from 'react'
import { Coin, GetObjectDataResponse, getObjectId, JsonRpcProvider } from '@mysten/sui.js'
import { useWallet } from '@mysten/wallet-adapter-react'
import { Accordion, AccordionDetails, AccordionSummary, Alert, Box, Button, Snackbar, Typography } from '@mui/material'
import ExpandMoreIcon from '@mui/icons-material/ExpandMore'

import {
  calcPoolLpValue,
  getLpCoinBalance,
  getLpCoinPoolId,
  getLpCoinTypeArgs,
  getUserLpCoins,
  withdraw,
} from '../../lib/amm'
import { ConnectWalletModal } from '../Wallet/ConnectWalletModal'
import { ellipsizeAddress } from '../../lib/util'

interface Props {
  pools: GetObjectDataResponse[]
  provider: JsonRpcProvider
  count: number
  getUpdatedPools: () => void
}

export const MyLPPositions = ({ pools, provider, count, getUpdatedPools }: Props) => {
  const [expanded, setExpanded] = useState(true)
  const [errorSnackbar, setErrorSnackbar] = useState({ open: false, message: '' })
  const [successSnackbar, setSuccessSnackbar] = useState({ open: false, message: '' })

  const [userLpCoins, setUserLpCoins] = useState<GetObjectDataResponse[]>([])

  const { wallet, connected } = useWallet()

  useEffect(() => {
    if (!wallet || !connected) {
      return
    }
    getUserLpCoins(provider, wallet).then(setUserLpCoins).catch(console.error)
  }, [provider, wallet, connected, count])

  const handleChange = (_event: React.SyntheticEvent, newExpanded: boolean) => {
    setExpanded(newExpanded)
  }

  const handleSnackbarClose = () => {
    setErrorSnackbar({ open: false, message: '' })
    setSuccessSnackbar({ open: false, message: '' })
  }

  const onWithdraw = async (lpCoin: GetObjectDataResponse) => {
    if (!wallet || !connected) {
      return
    }
    try {
      await withdraw(provider, wallet, lpCoin, 1)
      getUpdatedPools()
      setSuccessSnackbar({ open: true, message: 'Withdraw Success' })
    } catch (e) {
      console.error(e)
      setErrorSnackbar({ open: true, message: 'Withdraw Error' })
    }
  }

  if (!userLpCoins.length) {
    return (
      <Box sx={{ mx: 'auto', width: 500, mt: 3 }}>
        <Typography variant="h5" sx={{ mb: 2 }}>
          My LP Positions
        </Typography>
        <Typography variant="body1">List is empty</Typography>
      </Box>
    )
  }

  return (
    <Box sx={{ mx: 'auto', width: 532, mt: 3 }}>
      <Accordion expanded={expanded} onChange={handleChange} elevation={0}>
        <AccordionSummary expandIcon={<ExpandMoreIcon />} aria-controls="panel1a-content" id="panel1a-header">
          <Typography variant="h5">My LP Positions</Typography>
        </AccordionSummary>
        <AccordionDetails>
          {userLpCoins.map(lpCoin => {
            const [coinTypeA, coinTypeB] = getLpCoinTypeArgs(lpCoin)
            const symbolA = Coin.getCoinSymbol(coinTypeA)
            const symbolB = Coin.getCoinSymbol(coinTypeB)
            const lpAmount = getLpCoinBalance(lpCoin)

            // find pool corresponding to the lp coin
            const lpCoinPoolId = getLpCoinPoolId(lpCoin)
            const pool = pools.find(pool => getObjectId(pool) === lpCoinPoolId)
            if (pool === undefined) {
              return null
            }

            const [amountA, amountB] = calcPoolLpValue(pool, lpAmount)

            const poolId = getObjectId(pool)
            const lpCoinId = getObjectId(lpCoin)

            return (
              <Box
                key={`${lpCoinId}`}
                sx={{ boxShadow: '0px 5px 10px 0px rgba(0, 0, 0, 0.5)', borderRadius: '16px;', p: 3, mb: 3 }}
              >
                <Typography variant="body1" color="primary">
                  {symbolA}&nbsp;<span style={{ color: '#46505A' }}>-</span>&nbsp;{symbolB}&nbsp;
                  <Typography
                    component="a"
                    color="primary"
                    href={`https://explorer.devnet.sui.io/objects/${lpCoinId}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    variant="body2"
                  >
                    {`(${ellipsizeAddress(lpCoinId)})`}
                  </Typography>
                </Typography>
                <Typography variant="body2">{`${symbolA} value: ${amountA}`}</Typography>
                <Typography variant="body2">{`${symbolB} value: ${amountB}`}</Typography>
                <Typography variant="body2">{`LP amount: ${lpAmount}`}</Typography>
                <Typography
                  variant="body2"
                  component="a"
                  href={`https://explorer.devnet.sui.io/objects/${poolId}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  color="primary"
                  sx={{ textDecoration: 'none' }}
                >
                  Pool ID: {poolId}
                </Typography>

                {connected && wallet ? (
                  <Button
                    color="primary"
                    fullWidth
                    variant="contained"
                    sx={{ mt: 3 }}
                    onClick={() => onWithdraw(lpCoin)}
                  >
                    Withdraw
                  </Button>
                ) : (
                  <ConnectWalletModal />
                )}
              </Box>
            )
          })}
        </AccordionDetails>
      </Accordion>
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
