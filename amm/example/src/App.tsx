import { WalletStandardAdapterProvider } from '@mysten/wallet-adapter-all-wallets'
import { WalletProvider } from '@mysten/wallet-adapter-react'
import { Box, IconButton, Typography } from '@mui/material'
import TwitterIcon from '@mui/icons-material/Twitter'
import GitHubIcon from '@mui/icons-material/GitHub'

import { Amm } from './components/Amm/Amm'

const supportedWallets = [new WalletStandardAdapterProvider()]

function App() {
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
        <IconButton component="a" href="https://discord.gg/nTth43SUxJ" target="_blank" rel="noopener noreferrer">
          <img src="discord-icon.svg" alt="Discord icon" style={{ width: 32, height: 32 }} />
        </IconButton>
      </Box>
      <WalletProvider adapters={supportedWallets}>
        <Amm />
      </WalletProvider>
    </Box>
  )
}

export default App
