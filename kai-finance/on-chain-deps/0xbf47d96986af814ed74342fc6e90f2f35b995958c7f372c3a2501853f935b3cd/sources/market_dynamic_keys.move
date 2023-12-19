module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market_dynamic_keys {

    use 0x1::type_name;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market_dynamic_keys;

    struct BorrowFeeKey has copy, drop, store {
        type: type_name::TypeName,
    }
    struct BorrowFeeRecipientKey has copy, drop, store {
        dummy_field: bool,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun borrow_fee_key(a0: type_name::TypeName): market_dynamic_keys::BorrowFeeKey;
    native public fun borrow_fee_recipient_key(): market_dynamic_keys::BorrowFeeRecipientKey;

}
