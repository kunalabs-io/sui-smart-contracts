module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation_access {

    use 0x1::type_name;
    use sui::object;
    use sui::vec_set;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation_access;

    friend app;

    struct ObligationAccessStore has store, key {
        id: object::UID,
        lock_keys: vec_set::VecSet<type_name::TypeName>,
        reward_keys: vec_set::VecSet<type_name::TypeName>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun add_lock_key<T0: drop>(a0: &mut obligation_access::ObligationAccessStore);
 #[native_interface]
    native public(friend) fun remove_lock_key<T0: drop>(a0: &mut obligation_access::ObligationAccessStore);
 #[native_interface]
    native public(friend) fun add_reward_key<T0: drop>(a0: &mut obligation_access::ObligationAccessStore);
 #[native_interface]
    native public(friend) fun remove_reward_key<T0: drop>(a0: &mut obligation_access::ObligationAccessStore);
 #[native_interface]
    native public fun assert_lock_key_in_store<T0: drop>(a0: &obligation_access::ObligationAccessStore, a1: T0);
 #[native_interface]
    native public fun assert_reward_key_in_store<T0: drop>(a0: &obligation_access::ObligationAccessStore, a1: T0);

}
