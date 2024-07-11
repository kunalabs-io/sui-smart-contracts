module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow_referral {

    use 0x1::type_name;
    use sui::balance;
    use sui::object;
    use sui::tx_context;
    use sui::vec_set;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow_referral;

    friend app;
    friend borrow;

    struct BorrowReferral<phantom T0, T1> {
        id: object::UID,
        borrow_fee_discount: u64,
        referral_share: u64,
        borrowed: u64,
        referral_fee: balance::Balance<T0>,
        witness: T1,
    }
    struct BorrowReferralCfgKey<phantom T0> has copy, drop, store {
        dummy_field: bool,
    }
    struct BorrowedKey has copy, drop, store {
        dummy_field: bool,
    }
    struct ReferralFeeKey has copy, drop, store {
        dummy_field: bool,
    }
    struct AuthorizedWitnessList has key {
        id: object::UID,
        witness_list: vec_set::VecSet<type_name::TypeName>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun borrow_fee_discount<T0, T1>(a0: &borrow_referral::BorrowReferral<T0, T1>): u64;
 #[native_interface]
    native public fun borrowed<T0, T1>(a0: &borrow_referral::BorrowReferral<T0, T1>): u64;
 #[native_interface]
    native public fun referral_share<T0, T1>(a0: &borrow_referral::BorrowReferral<T0, T1>): u64;
 #[native_interface]
    native public fun fee_rate_base(): u64;
 #[native_interface]
    native public fun create_borrow_referral<T0, T1: drop>(a0: T1, a1: &borrow_referral::AuthorizedWitnessList, a2: u64, a3: u64, a4: &mut tx_context::TxContext): borrow_referral::BorrowReferral<T0, T1>;
 #[native_interface]
    native public fun calc_discounted_borrow_fee<T0, T1: drop>(a0: &borrow_referral::BorrowReferral<T0, T1>, a1: u64): u64;
 #[native_interface]
    native public fun calc_referral_fee<T0, T1: drop>(a0: &borrow_referral::BorrowReferral<T0, T1>, a1: u64): u64;
 #[native_interface]
    native public fun put_referral_fee<T0, T1: drop>(a0: &mut borrow_referral::BorrowReferral<T0, T1>, a1: balance::Balance<T0>);
 #[native_interface]
    native public(friend) fun put_referral_fee_v2<T0, T1: drop>(a0: &mut borrow_referral::BorrowReferral<T0, T1>, a1: balance::Balance<T0>);
 #[native_interface]
    native public fun increase_borrowed<T0, T1: drop>(a0: &mut borrow_referral::BorrowReferral<T0, T1>, a1: u64);
 #[native_interface]
    native public(friend) fun increase_borrowed_v2<T0, T1: drop>(a0: &mut borrow_referral::BorrowReferral<T0, T1>, a1: u64);
 #[native_interface]
    native public fun add_referral_cfg<T0, T1: drop, T2: drop+ store>(a0: &mut borrow_referral::BorrowReferral<T0, T1>, a1: T2);
 #[native_interface]
    native public fun get_referral_cfg<T0, T1: drop, T2: drop+ store>(a0: &borrow_referral::BorrowReferral<T0, T1>): &T2;
 #[native_interface]
    native public fun destroy_borrow_referral<T0, T1: drop>(a0: T1, a1: borrow_referral::BorrowReferral<T0, T1>): balance::Balance<T0>;
 #[native_interface]
    native public fun assert_authorized_witness<T0: drop>(a0: &borrow_referral::AuthorizedWitnessList);
 #[native_interface]
    native public(friend) fun add_witness<T0: drop>(a0: &mut borrow_referral::AuthorizedWitnessList);
 #[native_interface]
    native public(friend) fun remove_witness<T0: drop>(a0: &mut borrow_referral::AuthorizedWitnessList);
 #[native_interface]
    native public(friend) fun create_witness_list(a0: &mut tx_context::TxContext);

}
