module scallop_protocol::market_dynamic_keys {

    use 0x1::type_name;
    use scallop_protocol::market_dynamic_keys;

    struct BorrowFeeKey has copy, drop, store {
        type: type_name::TypeName,
    }
    struct BorrowFeeRecipientKey has copy, drop, store {
        dummy_field: bool,
    }
    struct SupplyLimitKey has copy, drop, store {
        type: type_name::TypeName,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun borrow_fee_key(a0: type_name::TypeName): market_dynamic_keys::BorrowFeeKey;
 #[native_interface]
    native public fun borrow_fee_recipient_key(): market_dynamic_keys::BorrowFeeRecipientKey;
 #[native_interface]
    native public fun supply_limit_key(a0: type_name::TypeName): market_dynamic_keys::SupplyLimitKey;

}
