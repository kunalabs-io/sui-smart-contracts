import { useState } from 'react'
import { Box, Button, List, Modal, Typography, ListItemButton, ListItemText, CircularProgress } from '@mui/material'
import { useWallet } from '@mysten/wallet-adapter-react'

export const ConnectWalletModal = () => {
  const { connected } = useWallet()

  const [open, setOpen] = useState(false)

  const handleClickOpen = () => {
    setOpen(true)
  }

  const handleClose = () => {
    setOpen(false)
  }

  const { wallets, wallet, select, connecting } = useWallet()

  const handleConnect = (walletName: string) => {
    select(walletName)
    handleClose()
  }

  const style = {
    position: 'absolute' as const,
    top: '50%',
    left: '50%',
    transform: 'translate(-50%, -50%)',
    width: 300,
    bgcolor: 'background.paper',
    border: '2px solid #000',
    boxShadow: 24,
    p: 4,
    borderRadius: 2,
  }

  return (
    <>
      {!connected && (
        <>
          <Button color="primary" fullWidth variant="contained" onClick={handleClickOpen}>
            Connect To Wallet
          </Button>
          <Modal open={open} onClose={handleClose}>
            <>
              {!connecting && (
                <Box sx={style}>
                  <Typography id="modal-modal-title" variant="h6" component="h2" align="center">
                    Select Wallet
                  </Typography>
                  <List>
                    {wallets.map((wallet, i) => (
                      <ListItemButton key={i} onClick={() => handleConnect(wallet.name)}>
                        <ListItemText primary={wallet.name} />
                      </ListItemButton>
                    ))}
                  </List>
                </Box>
              )}
              {connecting && (
                <Box sx={style}>
                  <Typography id="modal-modal-title" variant="h6" component="h2">
                    Connecting to {wallet ? wallet.name : 'Wallet'}
                  </Typography>
                  <CircularProgress />
                </Box>
              )}
            </>
          </Modal>
        </>
      )}
    </>
  )
}
