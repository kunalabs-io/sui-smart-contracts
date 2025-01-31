module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::reserve {

    use 0x1::fixed_point32;
    use 0x1::type_name;
    use sui::balance;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::balance_bag;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::supply_bag;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::reserve;

    friend market;

    struct BalanceSheets has drop {
        dummy_field: bool,
    }
    struct BalanceSheet has copy, store {
        cash: u64,
        debt: u64,
        revenue: u64,
        market_coin_supply: u64,
    }
    struct FlashLoanFees has drop {
        dummy_field: bool,
    }
    struct FlashLoan<phantom T0> {
        loan_amount: u64,
        fee: u64,
    }
    struct MarketCoin<phantom T0> has drop {
        dummy_field: bool,
    }
    struct Reserve has store, key {
        id: object::UID,
        market_coin_supplies: supply_bag::SupplyBag,
        underlying_balances: balance_bag::BalanceBag,
        balance_sheets: wit_table::WitTable<reserve::BalanceSheets, type_name::TypeName, reserve::BalanceSheet>,
        flash_loan_fees: wit_table::WitTable<reserve::FlashLoanFees, type_name::TypeName, u64>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun market_coin_supplies(a0: &reserve::Reserve): &supply_bag::SupplyBag;
 #[native_interface]
    native public fun underlying_balances(a0: &reserve::Reserve): &balance_bag::BalanceBag;
 #[native_interface]
    native public fun balance_sheets(a0: &reserve::Reserve): &wit_table::WitTable<reserve::BalanceSheets, type_name::TypeName, reserve::BalanceSheet>;
 #[native_interface]
    native public fun asset_types(a0: &reserve::Reserve): vector<type_name::TypeName>;
 #[native_interface]
    native public fun balance_sheet(a0: &reserve::BalanceSheet): (u64, u64, u64, u64);
 #[native_interface]
    native public(friend) fun new(a0: &mut tx_context::TxContext): reserve::Reserve;
 #[native_interface]
    native public(friend) fun register_coin<T0>(a0: &mut reserve::Reserve);
 #[native_interface]
    native public fun util_rate(a0: &reserve::Reserve, a1: type_name::TypeName): fixed_point32::FixedPoint32;
 #[native_interface]
    native public(friend) fun increase_debt(a0: &mut reserve::Reserve, a1: type_name::TypeName, a2: fixed_point32::FixedPoint32, a3: fixed_point32::FixedPoint32);
 #[native_interface]
    native public(friend) fun handle_repay<T0>(a0: &mut reserve::Reserve, a1: balance::Balance<T0>);
 #[native_interface]
    native public(friend) fun handle_borrow<T0>(a0: &mut reserve::Reserve, a1: u64): balance::Balance<T0>;
 #[native_interface]
    native public(friend) fun handle_liquidation<T0>(a0: &mut reserve::Reserve, a1: balance::Balance<T0>, a2: balance::Balance<T0>);
 #[native_interface]
    native public(friend) fun mint_market_coin<T0>(a0: &mut reserve::Reserve, a1: balance::Balance<T0>): balance::Balance<reserve::MarketCoin<T0>>;
 #[native_interface]
    native public(friend) fun redeem_underlying_coin<T0>(a0: &mut reserve::Reserve, a1: balance::Balance<reserve::MarketCoin<T0>>): balance::Balance<T0>;
 #[native_interface]
    native public(friend) fun set_flash_loan_fee<T0>(a0: &mut reserve::Reserve, a1: u64);
 #[native_interface]
    native public(friend) fun borrow_flash_loan<T0>(a0: &mut reserve::Reserve, a1: u64, a2: &mut tx_context::TxContext): (coin::Coin<T0>, reserve::FlashLoan<T0>);
 #[native_interface]
    native public(friend) fun repay_flash_loan<T0>(a0: &mut reserve::Reserve, a1: coin::Coin<T0>, a2: reserve::FlashLoan<T0>);
 #[native_interface]
    native public(friend) fun take_revenue<T0>(a0: &mut reserve::Reserve, a1: u64, a2: &mut tx_context::TxContext): coin::Coin<T0>;

}
