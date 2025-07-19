module 0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040::treasury {

    use 0x1::string;
    use sui::bag;
    use sui::coin;
    use sui::deny_list;
    use sui::object;
    use sui::tx_context;
    use 0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040::treasury;

    struct ControlledTreasury<phantom T0> has key {
        id: object::UID,
        admin_count: u8,
        treasury_cap: coin::TreasuryCap<T0>,
        deny_cap: coin::DenyCapV2<T0>,
        roles: bag::Bag,
    }
    struct AdminCap has drop, store {
        dummy_field: bool,
    }
    struct MinterCap has drop, store {
        limit: u64,
        epoch: u64,
        left: u64,
    }
    struct PauserCap has drop, store {
        dummy_field: bool,
    }
    struct MintEvent<phantom T0> has copy, drop {
        amount: u64,
        to: address,
        tx_id: vector<u8>,
        index: u32,
    }
    struct BurnEvent<phantom T0> has copy, drop {
        amount: u64,
        from: address,
    }
    struct RoleKey<phantom T0> has copy, drop, store {
        owner: address,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new_admin_cap(): treasury::AdminCap;
 #[native_interface]
    native public fun new_minter_cap(a0: u64, a1: &tx_context::TxContext): treasury::MinterCap;
 #[native_interface]
    native public fun new_pauser_cap(): treasury::PauserCap;
 #[native_interface]
    native public fun new<T0>(a0: coin::TreasuryCap<T0>, a1: coin::DenyCapV2<T0>, a2: address, a3: &mut tx_context::TxContext): treasury::ControlledTreasury<T0>;
 #[native_interface]
    native public fun share<T0>(a0: treasury::ControlledTreasury<T0>);
 #[native_interface]
    native public fun deconstruct<T0>(a0: treasury::ControlledTreasury<T0>, a1: &mut tx_context::TxContext): (coin::TreasuryCap<T0>, coin::DenyCapV2<T0>, bag::Bag);
 #[native_interface]
    native public fun add_capability<T0, T1: drop+ store>(a0: &mut treasury::ControlledTreasury<T0>, a1: address, a2: T1, a3: &mut tx_context::TxContext);
 #[native_interface]
    native public fun remove_capability<T0, T1: drop+ store>(a0: &mut treasury::ControlledTreasury<T0>, a1: address, a2: &mut tx_context::TxContext);
 #[native_interface]
    native public fun mint_and_transfer<T0>(a0: &mut treasury::ControlledTreasury<T0>, a1: u64, a2: address, a3: &deny_list::DenyList, a4: vector<vector<u8>>, a5: vector<u8>, a6: u16, a7: vector<u8>, a8: u32, a9: &mut tx_context::TxContext);
 #[native_interface]
    native public fun enable_global_pause<T0>(a0: &mut treasury::ControlledTreasury<T0>, a1: &mut deny_list::DenyList, a2: vector<vector<u8>>, a3: vector<u8>, a4: u16, a5: &mut tx_context::TxContext);
 #[native_interface]
    native public fun disable_global_pause<T0>(a0: &mut treasury::ControlledTreasury<T0>, a1: &mut deny_list::DenyList, a2: vector<vector<u8>>, a3: vector<u8>, a4: u16, a5: &mut tx_context::TxContext);
 #[native_interface]
    native public fun has_cap<T0, T1: store>(a0: &treasury::ControlledTreasury<T0>, a1: address): bool;
 #[native_interface]
    native public fun is_global_pause_enabled<T0>(a0: &deny_list::DenyList): bool;
 #[native_interface]
    native public fun list_roles<T0>(a0: &treasury::ControlledTreasury<T0>, a1: address): vector<string::String>;

}
