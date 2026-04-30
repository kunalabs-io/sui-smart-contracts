module xbtc::xbtc;

public struct XBTC has drop {}

public struct XBTCReceiver has key, store {
    id: object::UID,
    receiver: address,
}

public struct MintEvent has copy, drop {
    minter: address,
    receiver: address,
    amount: u64,
}

public struct BurnEvent has copy, drop {
    account: address,
    amount: u64,
}

public struct AddDenyListEvent has copy, drop {
    denylister: address,
    account: address,
}

public struct RemoveDenyListEvent has copy, drop {
    denylister: address,
    account: address,
}

public struct BatchAddDenyListEvent has copy, drop {
    denylister: address,
    accounts: vector<address>,
}

public struct BatchRemoveDenyListEvent has copy, drop {
    denylister: address,
    accounts: vector<address>,
}

public struct PauseEvent has copy, drop {
    pauser: address,
    paused: bool,
}

public struct SetReceiverEvent has copy, drop {
    denylister: address,
    old_receiver: address,
    new_receiver: address,
}

public struct TransferMinterRoleEvent has copy, drop {
    old_minter: address,
    new_minter: address,
}

public struct TransferDenylisterRoleEvent has copy, drop {
    old_denylister: address,
    new_denylister: address,
}
