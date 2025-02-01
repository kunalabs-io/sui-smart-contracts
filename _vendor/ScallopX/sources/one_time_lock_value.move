module 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::one_time_lock_value {

    use sui::object;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::one_time_lock_value;

    struct OneTimeLockValue<T0: copy+ drop+ store> has store, key {
        id: object::UID,
        value: T0,
        lock_until_epoch: u64,
        valid_before_epoch: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun lock_until_epoch<T0: copy+ drop+ store>(a0: &one_time_lock_value::OneTimeLockValue<T0>): u64;
 #[native_interface]
    native public fun valid_before_epoch<T0: copy+ drop+ store>(a0: &one_time_lock_value::OneTimeLockValue<T0>): u64;
 #[native_interface]
    native public fun new<T0: copy+ drop+ store>(a0: T0, a1: u64, a2: u64, a3: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<T0>;
 #[native_interface]
    native public fun get_value<T0: copy+ drop+ store>(a0: one_time_lock_value::OneTimeLockValue<T0>, a1: &mut tx_context::TxContext): T0;
 #[native_interface]
    native public fun destroy<T0: copy+ drop+ store>(a0: one_time_lock_value::OneTimeLockValue<T0>, a1: &mut tx_context::TxContext);

}
