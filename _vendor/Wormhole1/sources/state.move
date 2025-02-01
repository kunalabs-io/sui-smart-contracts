module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::state {

    use sui::object;
    use sui::package;
    use sui::table;
    use sui::tx_context;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::attest_token;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer_with_payload;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::create_wrapped;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::migrate;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::register_chain;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::setup;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::state;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::token_registry;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_tokens;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_tokens_with_payload;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::upgrade_contract;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::vaa;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::consumed_vaas;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::emitter;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::publish_message;

    friend attest_token;
    friend complete_transfer;
    friend complete_transfer_with_payload;
    friend create_wrapped;
    friend migrate;
    friend register_chain;
    friend setup;
    friend transfer_tokens;
    friend transfer_tokens_with_payload;
    friend upgrade_contract;
    friend vaa;

    struct LatestOnly has drop {
        dummy_field: bool,
    }
    struct State has store, key {
        id: object::UID,
        governance_chain: u16,
        governance_contract: external_address::ExternalAddress,
        consumed_vaas: consumed_vaas::ConsumedVAAs,
        emitter_cap: emitter::EmitterCap,
        emitter_registry: table::Table<u16, external_address::ExternalAddress>,
        token_registry: token_registry::TokenRegistry,
        upgrade_cap: package::UpgradeCap,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun new(a0: emitter::EmitterCap, a1: package::UpgradeCap, a2: u16, a3: external_address::ExternalAddress, a4: &mut tx_context::TxContext): state::State;
 #[native_interface]
    native public fun governance_module(): bytes32::Bytes32;
 #[native_interface]
    native public fun governance_chain(a0: &state::State): u16;
 #[native_interface]
    native public fun governance_contract(a0: &state::State): external_address::ExternalAddress;
 #[native_interface]
    native public fun borrow_token_registry(a0: &state::State): &token_registry::TokenRegistry;
 #[native_interface]
    native public fun borrow_emitter_registry(a0: &state::State): &table::Table<u16, external_address::ExternalAddress>;
 #[native_interface]
    native public fun verified_asset<T0>(a0: &state::State): token_registry::VerifiedAsset<T0>;
 #[native_interface]
    native public(friend) fun assert_latest_only(a0: &state::State): state::LatestOnly;
 #[native_interface]
    native public(friend) fun assert_latest_only_specified<T0>(a0: &state::State): state::LatestOnly;
 #[native_interface]
    native public(friend) fun borrow_mut_consumed_vaas(a0: &state::LatestOnly, a1: &mut state::State): &mut consumed_vaas::ConsumedVAAs;
 #[native_interface]
    native public(friend) fun borrow_mut_consumed_vaas_unchecked(a0: &mut state::State): &mut consumed_vaas::ConsumedVAAs;
 #[native_interface]
    native public(friend) fun prepare_wormhole_message(a0: &state::LatestOnly, a1: &mut state::State, a2: u32, a3: vector<u8>): publish_message::MessageTicket;
 #[native_interface]
    native public(friend) fun borrow_mut_token_registry(a0: &state::LatestOnly, a1: &mut state::State): &mut token_registry::TokenRegistry;
 #[native_interface]
    native public(friend) fun borrow_mut_emitter_registry(a0: &state::LatestOnly, a1: &mut state::State): &mut table::Table<u16, external_address::ExternalAddress>;
 #[native_interface]
    native public(friend) fun current_package(a0: &state::LatestOnly, a1: &state::State): object::ID;
 #[native_interface]
    native public(friend) fun authorize_upgrade(a0: &mut state::State, a1: bytes32::Bytes32): package::UpgradeTicket;
 #[native_interface]
    native public(friend) fun commit_upgrade(a0: &mut state::State, a1: package::UpgradeReceipt): (object::ID, object::ID);
 #[native_interface]
    native public(friend) fun migrate_version(a0: &mut state::State);
 #[native_interface]
    native public(friend) fun assert_authorized_digest(a0: &state::LatestOnly, a1: &state::State, a2: bytes32::Bytes32);
 #[native_interface]
    native public(friend) fun migrate__v__0_2_0(a0: &mut state::State);

}
