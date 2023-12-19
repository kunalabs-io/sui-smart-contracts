module 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::supply_bag {

    use sui::bag;
    use sui::balance;
    use sui::object;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::supply_bag;

    struct SupplyBag has store {
        id: object::UID,
        bag: bag::Bag,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: &mut tx_context::TxContext): supply_bag::SupplyBag;
 #[native_interface]
    native public fun init_supply<T0: drop>(a0: T0, a1: &mut supply_bag::SupplyBag);
 #[native_interface]
    native public fun increase_supply<T0>(a0: &mut supply_bag::SupplyBag, a1: u64): balance::Balance<T0>;
 #[native_interface]
    native public fun decrease_supply<T0>(a0: &mut supply_bag::SupplyBag, a1: balance::Balance<T0>): u64;
 #[native_interface]
    native public fun supply_value<T0>(a0: &supply_bag::SupplyBag): u64;
 #[native_interface]
    native public fun contains<T0>(a0: &supply_bag::SupplyBag): bool;
 #[native_interface]
    native public fun bag(a0: &supply_bag::SupplyBag): &bag::Bag;
 #[native_interface]
    native public fun destroy_empty(a0: supply_bag::SupplyBag);

}
