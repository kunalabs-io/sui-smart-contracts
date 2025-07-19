module 0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040::multisig {

    use sui::tx_context;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun derive_multisig_address(a0: vector<vector<u8>>, a1: vector<u8>, a2: u16): address;
 #[native_interface]
    native public fun is_sender_multisig(a0: vector<vector<u8>>, a1: vector<u8>, a2: u16, a3: &tx_context::TxContext): bool;
 #[native_interface]
    native public fun ed25519_key_to_address(a0: &vector<u8>): address;
 #[native_interface]
    native public fun secp256k1_key_to_address(a0: &vector<u8>): address;
 #[native_interface]
    native public fun secp256r1_key_to_address(a0: &vector<u8>): address;

}
