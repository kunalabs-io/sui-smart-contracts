import { useState } from 'react'
import { Box } from '@mui/material'
import { Typography } from '@mui/material'
import Button from '@mui/material/Button'
import { Coin, GetObjectDataResponse, JsonRpcProvider } from '@mysten/sui.js'
import { useWallet } from '@mysten/wallet-adapter-react'

import { getPoolBalances, getPoolCoinTypeArgs } from '../../lib/amm'
import { AddDeposit } from './AddDeposit'
import { ConnectWalletModal } from '../Wallet/ConnectWalletModal'

interface Props {
  pools: GetObjectDataResponse[]
  provider: JsonRpcProvider
  getUpdatedPools: () => void
}

export const Pools = ({ pools, provider, getUpdatedPools }: Props) => {
  const { wallet, connected } = useWallet()

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

  return (
    <Box sx={{ mx: 'auto', width: 500, mt: 3 }}>
      <Typography variant="h5" sx={{ mb: 2 }}>
        Pool List
      </Typography>
      {pools.map(pool => {
        const [coinTypeA, coinTypeB] = getPoolCoinTypeArgs(pool)
        const symbolA = Coin.getCoinSymbol(coinTypeA)
        const symbolB = Coin.getCoinSymbol(coinTypeB)
        const [balanceA, balanceB, lpSupply] = getPoolBalances(pool)
        return (
          <Box
            key={`${symbolA}-${symbolB}`}
            sx={{ boxShadow: '0px 5px 10px 0px rgba(0, 0, 0, 0.5)', borderRadius: '16px;', p: 3, mb: 3 }}
          >
            <Typography variant="body1" color="primary">{`${symbolA}-${symbolB}`}</Typography>
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

      {activePool && (
        <AddDeposit
          isOpen={isOpenAddDeposit}
          onClose={handleCloseAddDepositModal}
          pool={activePool}
          provider={provider}
          getUpdatedPools={getUpdatedPools}
        />
      )}
    </Box>
  )
}
