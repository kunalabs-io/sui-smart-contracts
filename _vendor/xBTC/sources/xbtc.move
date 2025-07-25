module 0x876A4B7BCE8AEAEF60464C11F4026903E9AFACAB79B9B142686158AA86560B50::xbtc {

    use sui::coin;
    use sui::deny_list;
    use sui::object;
    use sui::tx_context;
    use 0x876A4B7BCE8AEAEF60464C11F4026903E9AFACAB79B9B142686158AA86560B50::xbtc;

    struct XBTC has drop {
        dummy_field: bool,
    }
    struct XBTCReceiver has store, key {
        id: object::UID,
        receiver: address,
    }
    struct MintEvent has copy, drop {
        minter: address,
        receiver: address,
        amount: u64,
    }
    struct BurnEvent has copy, drop {
        account: address,
        amount: u64,
    }
    struct AddDenyListEvent has copy, drop {
        denylister: address,
        account: address,
    }
    struct RemoveDenyListEvent has copy, drop {
        denylister: address,
        account: address,
    }
    struct BatchAddDenyListEvent has copy, drop {
        denylister: address,
        accounts: vector<address>,
    }
    struct BatchRemoveDenyListEvent has copy, drop {
        denylister: address,
        accounts: vector<address>,
    }
    struct PauseEvent has copy, drop {
        pauser: address,
        paused: bool,
    }
    struct SetReceiverEvent has copy, drop {
        denylister: address,
        old_receiver: address,
        new_receiver: address,
    }
    struct TransferMinterRoleEvent has copy, drop {
        old_minter: address,
        new_minter: address,
    }
    struct TransferDenylisterRoleEvent has copy, drop {
        old_denylister: address,
        new_denylister: address,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public entry fun mint(a0: &mut coin::TreasuryCap<xbtc::XBTC>, a1: &xbtc::XBTCReceiver, a2: u64, a3: address, a4: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun burn(a0: &mut coin::TreasuryCap<xbtc::XBTC>, a1: coin::Coin<xbtc::XBTC>, a2: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun set_receiver(a0: &mut coin::DenyCapV2<xbtc::XBTC>, a1: &mut xbtc::XBTCReceiver, a2: address, a3: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun set_pause(a0: &mut deny_list::DenyList, a1: &mut coin::DenyCapV2<xbtc::XBTC>, a2: bool, a3: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun add_to_deny_list(a0: &mut deny_list::DenyList, a1: &mut coin::DenyCapV2<xbtc::XBTC>, a2: address, a3: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun remove_from_deny_list(a0: &mut deny_list::DenyList, a1: &mut coin::DenyCapV2<xbtc::XBTC>, a2: address, a3: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun batch_add_to_deny_list(a0: &mut deny_list::DenyList, a1: &mut coin::DenyCapV2<xbtc::XBTC>, a2: vector<address>, a3: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun batch_remove_from_deny_list(a0: &mut deny_list::DenyList, a1: &mut coin::DenyCapV2<xbtc::XBTC>, a2: vector<address>, a3: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun transfer_minter_role(a0: coin::TreasuryCap<xbtc::XBTC>, a1: address, a2: &mut tx_context::TxContext);
 #[native_interface]
    native public entry fun transfer_denylister_role(a0: coin::DenyCapV2<xbtc::XBTC>, a1: address, a2: &mut tx_context::TxContext);

}
