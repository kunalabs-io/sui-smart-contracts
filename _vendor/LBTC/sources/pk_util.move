module 0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040::pk_util {

    use 0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040::multisig;

    friend multisig;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun validate_pks(a0: &vector<vector<u8>>);
 #[native_interface]
    native public(friend) fun is_valid_key(a0: &vector<u8>): bool;

}
