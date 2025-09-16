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
}
