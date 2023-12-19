module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_with_payload {

    use sui::object;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::normalized_amount;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_tokens_with_payload;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_with_payload;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;

    friend transfer_tokens_with_payload;

    struct TransferWithPayload has drop {
        amount: normalized_amount::NormalizedAmount,
        token_address: external_address::ExternalAddress,
        token_chain: u16,
        redeemer: external_address::ExternalAddress,
        redeemer_chain: u16,
        sender: external_address::ExternalAddress,
        payload: vector<u8>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun new(a0: object::ID, a1: normalized_amount::NormalizedAmount, a2: external_address::ExternalAddress, a3: u16, a4: external_address::ExternalAddress, a5: u16, a6: vector<u8>): transfer_with_payload::TransferWithPayload;
 #[native_interface]
    native public fun take_payload(a0: transfer_with_payload::TransferWithPayload): vector<u8>;
 #[native_interface]
    native public fun amount(a0: &transfer_with_payload::TransferWithPayload): normalized_amount::NormalizedAmount;
 #[native_interface]
    native public fun token_address(a0: &transfer_with_payload::TransferWithPayload): external_address::ExternalAddress;
 #[native_interface]
    native public fun token_chain(a0: &transfer_with_payload::TransferWithPayload): u16;
 #[native_interface]
    native public fun redeemer(a0: &transfer_with_payload::TransferWithPayload): external_address::ExternalAddress;
 #[native_interface]
    native public fun redeemer_id(a0: &transfer_with_payload::TransferWithPayload): object::ID;
 #[native_interface]
    native public fun redeemer_chain(a0: &transfer_with_payload::TransferWithPayload): u16;
 #[native_interface]
    native public fun sender(a0: &transfer_with_payload::TransferWithPayload): external_address::ExternalAddress;
 #[native_interface]
    native public fun payload(a0: &transfer_with_payload::TransferWithPayload): vector<u8>;
 #[native_interface]
    native public fun deserialize(a0: vector<u8>): transfer_with_payload::TransferWithPayload;
 #[native_interface]
    native public fun serialize(a0: transfer_with_payload::TransferWithPayload): vector<u8>;

}
