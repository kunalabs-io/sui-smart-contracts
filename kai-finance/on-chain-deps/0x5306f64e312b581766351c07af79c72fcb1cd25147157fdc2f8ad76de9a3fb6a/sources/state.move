module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state {

    use sui::balance;
    use sui::clock;
    use sui::object;
    use sui::package;
    use sui::sui;
    use sui::table;
    use sui::tx_context;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::consumed_vaas;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::emitter;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::fee_collector;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian_set;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::migrate;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::publish_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::set_fee;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::setup;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::transfer_fee;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::update_guardian_set;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::upgrade_contract;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::vaa;

    friend emitter;
    friend governance_message;
    friend migrate;
    friend publish_message;
    friend set_fee;
    friend setup;
    friend transfer_fee;
    friend update_guardian_set;
    friend upgrade_contract;
    friend vaa;

    struct LatestOnly has drop {
        dummy_field: bool,
    }
    struct State has store, key {
        id: object::UID,
        governance_chain: u16,
        governance_contract: external_address::ExternalAddress,
        guardian_set_index: u32,
        guardian_sets: table::Table<u32, guardian_set::GuardianSet>,
        guardian_set_seconds_to_live: u32,
        consumed_vaas: consumed_vaas::ConsumedVAAs,
        fee_collector: fee_collector::FeeCollector,
        upgrade_cap: package::UpgradeCap,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun new(a0: package::UpgradeCap, a1: u16, a2: external_address::ExternalAddress, a3: u32, a4: vector<guardian::Guardian>, a5: u32, a6: u64, a7: &mut tx_context::TxContext): state::State;
 #[native_interface]
    native public fun chain_id(): u16;
 #[native_interface]
    native public fun governance_module(): bytes32::Bytes32;
 #[native_interface]
    native public fun governance_chain(a0: &state::State): u16;
 #[native_interface]
    native public fun governance_contract(a0: &state::State): external_address::ExternalAddress;
 #[native_interface]
    native public fun guardian_set_index(a0: &state::State): u32;
 #[native_interface]
    native public fun guardian_set_seconds_to_live(a0: &state::State): u32;
 #[native_interface]
    native public fun guardian_set_at(a0: &state::State, a1: u32): &guardian_set::GuardianSet;
 #[native_interface]
    native public fun message_fee(a0: &state::State): u64;
 #[native_interface]
    native public(friend) fun assert_latest_only(a0: &state::State): state::LatestOnly;
 #[native_interface]
    native public(friend) fun deposit_fee(a0: &state::LatestOnly, a1: &mut state::State, a2: balance::Balance<sui::SUI>);
 #[native_interface]
    native public(friend) fun withdraw_fee(a0: &state::LatestOnly, a1: &mut state::State, a2: u64): balance::Balance<sui::SUI>;
 #[native_interface]
    native public(friend) fun borrow_mut_consumed_vaas(a0: &state::LatestOnly, a1: &mut state::State): &mut consumed_vaas::ConsumedVAAs;
 #[native_interface]
    native public(friend) fun borrow_mut_consumed_vaas_unchecked(a0: &mut state::State): &mut consumed_vaas::ConsumedVAAs;
 #[native_interface]
    native public(friend) fun expire_guardian_set(a0: &state::LatestOnly, a1: &mut state::State, a2: &clock::Clock);
 #[native_interface]
    native public(friend) fun add_new_guardian_set(a0: &state::LatestOnly, a1: &mut state::State, a2: guardian_set::GuardianSet);
 #[native_interface]
    native public(friend) fun set_message_fee(a0: &state::LatestOnly, a1: &mut state::State, a2: u64);
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
