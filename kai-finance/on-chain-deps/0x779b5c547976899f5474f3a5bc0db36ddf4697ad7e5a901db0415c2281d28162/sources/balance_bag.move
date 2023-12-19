module 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::balance_bag {

    use sui::bag;
    use sui::balance;
    use sui::object;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::balance_bag;

    struct BalanceBag has store {
        id: object::UID,
        bag: bag::Bag,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: &mut tx_context::TxContext): balance_bag::BalanceBag;
 #[native_interface]
    native public fun init_balance<T0>(a0: &mut balance_bag::BalanceBag);
 #[native_interface]
    native public fun join<T0>(a0: &mut balance_bag::BalanceBag, a1: balance::Balance<T0>);
 #[native_interface]
    native public fun split<T0>(a0: &mut balance_bag::BalanceBag, a1: u64): balance::Balance<T0>;
 #[native_interface]
    native public fun value<T0>(a0: &balance_bag::BalanceBag): u64;
 #[native_interface]
    native public fun contains<T0>(a0: &balance_bag::BalanceBag): bool;
 #[native_interface]
    native public fun bag(a0: &balance_bag::BalanceBag): &bag::Bag;
 #[native_interface]
    native public fun destroy_empty(a0: balance_bag::BalanceBag);

}
