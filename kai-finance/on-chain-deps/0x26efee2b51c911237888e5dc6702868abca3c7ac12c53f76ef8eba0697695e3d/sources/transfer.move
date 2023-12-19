module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer {

    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::normalized_amount;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_tokens;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;

    friend complete_transfer;
    friend transfer_tokens;

    struct Transfer {
        amount: normalized_amount::NormalizedAmount,
        token_address: external_address::ExternalAddress,
        token_chain: u16,
        recipient: external_address::ExternalAddress,
        recipient_chain: u16,
        relayer_fee: normalized_amount::NormalizedAmount,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun new(a0: normalized_amount::NormalizedAmount, a1: external_address::ExternalAddress, a2: u16, a3: external_address::ExternalAddress, a4: u16, a5: normalized_amount::NormalizedAmount): transfer::Transfer;
 #[native_interface]
    native public(friend) fun unpack(a0: transfer::Transfer): (normalized_amount::NormalizedAmount, external_address::ExternalAddress, u16, external_address::ExternalAddress, u16, normalized_amount::NormalizedAmount);
 #[native_interface]
    native public(friend) fun deserialize(a0: vector<u8>): transfer::Transfer;
 #[native_interface]
    native public(friend) fun serialize(a0: transfer::Transfer): vector<u8>;

}
