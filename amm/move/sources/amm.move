module 0x0::amm {
    use std::type_name::{Self, TypeName};
    use std::vector;
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance, Supply};
    use sui::coin::{Self, Coin};
    use sui::balance::{create_supply};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::math;
    use sui::table::{Self, Table};

    /* ================= errors ================= */

    /// The pool balance differs from the acceptable.
    const EExcessiveSlippage: u64 = 0;
    /// The input amount is zero.
    const EZeroInput: u64 = 1;
    /// The pool ID doesn't match the required.
    const EInvalidPoolID: u64 = 2;
    /// There's no liquidity in the pool.
    const ENoLiquidity: u64 = 3;
    /// Fee parameter is not valid.
    const EInvalidFeeParam: u64 = 4;
    /// The provided admin capability doesn't belong to this pool.
    const EInvalidAdminCap: u64 = 5;
    /// Pool pair coin types must be ordered alphabetically (`A` < `B`) and mustn't be equal.
    const EInvalidPair: u64 = 6;
    /// Pool for this pair already exists.
    const EPoolAlreadyExists: u64 = 7;

    /* ================= events ================= */

    struct PoolCreationEvent has copy, drop {
        pool_id: ID,
    }

    /* ================= constants ================= */

    /// The number of basis points in 100%.
    const BPS_IN_100_PCT: u64 = 100 * 100;

    /* ================= LPCoin ================= */

    /// Pool LP token witness.
    struct LP<phantom A, phantom B> has drop { }

    /// Represents liquidity provider's share of pool balances.
    struct LPCoin<phantom A, phantom B> has key, store {
        id: UID,
        pool_id: ID,
        balance: Balance<LP<A, B>>
    }

    /// Public getter for the LP coin's value.
    public fun lp_coin_value<A, B>(self: &LPCoin<A, B>): u64 {
        balance::value(&self.balance)
    }

    /// Get an immutable reference to the ID of the pool the LP coin belongs to.
    public fun lp_coin_pool_id<A, B>(self: &LPCoin<A, B>): &ID {
        &self.pool_id
    }

    /// Create an LP coin with zero value.
    public fun lp_coin_zero<A, B>(pool: &Pool<A, B>, ctx: &mut TxContext): LPCoin<A, B> {
        LPCoin {
            id: object::new(ctx),
            pool_id: object::id(pool),
            balance: balance::zero<LP<A, B>>()
        }
    }

    /// Take out `value` from the provided LP coin and put it into a new coin.
    public fun lp_coin_split<A, B>(self: &mut LPCoin<A, B>, value: u64, ctx: &mut TxContext): LPCoin<A, B> {
        LPCoin<A, B> {
            id: object::new(ctx),
            pool_id: self.pool_id,
            balance: balance::split(&mut self.balance, value)
        }
    }

    /* ================= Pool ================= */

    /// Pool represents an AMM Pool.
    struct Pool<phantom A, phantom B> has key {
        id: UID,
        balance_a: Balance<A>,
        balance_b: Balance<B>,
        lp_supply: Supply<LP<A, B>>,
        /// The liquidity provider fees expressed in basis points (1 bps is 0.01%)
        lp_fee_bps: u64,
        /// Admin fees are calculated as a percentage of liquidity provider fees.
        admin_fee_pct: u64,
        /// Admin fees are deposited into this balance. They can be colleced by
        /// this pool's PoolAdminCap bearer.
        admin_fee_balance: Balance<LP<A, B>>
    }

    /// Returns the balances of token A and B present in the pool and the total
    /// supply of LP coins.
    public fun pool_values<A, B>(pool: &Pool<A, B>): (u64, u64, u64) {
        (
            balance::value(&pool.balance_a),
            balance::value(&pool.balance_b),
            balance::supply_value(&pool.lp_supply)
        )
    }

    /// Returns the pool fee info.
    public fun pool_fees<A, B>(pool: &Pool<A, B>): (u64, u64) {
        (pool.lp_fee_bps, pool.admin_fee_pct)
    }

    /// Returns the value of collected admin fees stored in the pool.
    public fun pool_admin_fee_value<A, B>(pool: &Pool<A, B>): u64 {
        balance::value(&pool.admin_fee_balance)
    }

    /* ================= PoolList ================= */

    /// `PoolList` stores a table of all pools created which is used to guarantee
    /// that only one pool per currency pair can exist.
    struct PoolList has key, store {
        id: UID,
        table: Table<PoolListItem, bool>,
    }

    /// An item in the `PoolList` table. Represents a pool's currency pair.
    struct PoolListItem has copy, drop, store  {
        a: TypeName,
        b: TypeName
    }

    /// Creat an empty `PoolList`.
    fun empty_list(ctx: &mut TxContext): PoolList {
        PoolList { 
            id: object::new(ctx),
            table: table::new(ctx)
        }
    }

    // returns:
    //    0 if a < b,
    //    1 if a == b,
    //    2 if a > b
    fun cmp_type_names(a: &TypeName, b: &TypeName): u8 {
        let bytes_a = std::ascii::as_bytes(type_name::borrow_string(a));
        let bytes_b = std::ascii::as_bytes(type_name::borrow_string(b));

        let len_a = vector::length(bytes_a);
        let len_b = vector::length(bytes_b);

        let i = 0;
        let n = math::min(len_a, len_b);
        while (i < n) {
            let a = *vector::borrow(bytes_a, i);
            let b = *vector::borrow(bytes_b, i);

            if (a < b) {
                return 0
            };
            if (a > b) {
                return 2
            };
            i = i + 1;
        };

        if (len_a == len_b) {
            return 1
        };

        return if (len_a < len_b) {
            0
        } else {
            2
        }
    }

    /// Add a new coin type tuple (`A`, `B`) to the list. Types must be sorted alphabetically (ASCII ordered)
    /// such that `A` < `B`. They also cannot be equal.
    /// Aborts when coin types are the same.
    /// Aborts when coin types are not in order (type `A` must come before `B` alphabetically).
    /// Aborts when coin type tuple is already in the list.
    fun list_add<A, B>(self: &mut PoolList) {
        let a = type_name::get<A>();
        let b = type_name::get<B>();
        assert!(cmp_type_names(&a, &b) == 0, EInvalidPair);

        let item = PoolListItem{ a, b };
        assert!(table::contains(&self.table, item) == false, EPoolAlreadyExists);

        table::add(&mut self.table, item, true)
    }

    /* ================= AdminCap ================= */

    /// Capability allowing the bearer to execute admin operations on the pools
    /// (e.g. withdraw admin fees). There's only one `AdminCap` created during module
    /// initialization that's valid for all pools.
    struct AdminCap has key, store {
        id: UID,
    }

    /* ================= math ================= */

    /// Calculates (a * b) / c. Errors if result doesn't fit into u64.
    fun muldiv(a: u64, b: u64, c: u64): u64 {
        ((((a as u128) * (b as u128)) / (c as u128)) as u64)
    }

    /// Calculates ceil_div((a * b), c). Errors if result doesn't fit into u64.
    fun ceil_muldiv(a: u64, b: u64, c: u64): u64 {
        (ceil_div_u128((a as u128) * (b as u128), (c as u128)) as u64)
    }

    /// Calculates sqrt(a * b).
    fun mulsqrt(a: u64, b: u64): u64 {
        (math::sqrt_u128((a as u128) * (b as u128)) as u64)
    }

    /// Calculates (a * b) / c for u128. Errors if result doesn't fit into u128.
    fun muldiv_u128(a: u128, b: u128, c: u128): u128 {
        ((((a as u256) * (b as u256)) / (c as u256)) as u128)
    }

    /// Calculates ceil(a / b).
    fun ceil_div_u128(a: u128, b: u128): u128 {
        if (a == 0) 0 else (a - 1) / b + 1
    }

    /* ================= util ================= */

    /// Mints new LPCoin of `amount`.
    fun lp_increase_supply<A, B>(
        pool: &mut Pool<A, B>, amount: u64, ctx: &mut TxContext
    ): LPCoin<A, B> {
       let lp_balance = balance::increase_supply(&mut pool.lp_supply, amount);
       LPCoin {
            id: object::new(ctx),
            pool_id: object::uid_to_inner(&pool.id),
            balance: lp_balance,
       }
    }    

    /// Destroys the provided balance if zero, otherwise converts it to a `Coin`
    /// and transfers it to recipient.
    fun destroy_or_transfer_balance<T>(balance: Balance<T>, recipient: address, ctx: &mut TxContext) {
        if (balance::value(&balance) == 0) {
            balance::destroy_zero(balance);
            return
        };
        transfer::transfer(
            coin::from_balance(balance, ctx),
            recipient
        );
    }

    /// Destroys the provided LP coin if zero, otherwise transfer's it to recipient.
    fun destroy_or_transfer_lp_coin<A, B>(lp_coin: LPCoin<A, B>, recipient: address) {
        if (lp_coin_value(&lp_coin) > 0) {
            transfer::transfer(lp_coin, recipient)
        } else {
            let LPCoin {id, pool_id: _, balance} = lp_coin;
            object::delete(id);
            balance::destroy_zero(balance);
        }
    }

    /* ================= main logic ================= */

    /// Initializes the `PoolList` objects and shares it, and transfers `AdminCap` to sender.
    fun init(ctx: &mut TxContext) {
        transfer::share_object(empty_list(ctx));
        transfer::transfer(
            AdminCap{ id: object::new(ctx) },
            tx_context::sender(ctx)
        )
    }

    /// Creates a new Pool with provided initial balances. Returns the initial LP coins.
    public fun create_pool<A, B>(
        list: &mut PoolList,
        init_a: Balance<A>,
        init_b: Balance<B>,
        lp_fee_bps: u64,
        admin_fee_pct: u64,
        ctx: &mut TxContext,
    ): LPCoin<A, B> {
        // sanity checks
        assert!(balance::value(&init_a) > 0 && balance::value(&init_b) > 0, EZeroInput);
        assert!(lp_fee_bps < BPS_IN_100_PCT, EInvalidFeeParam);
        assert!(admin_fee_pct <= 100, EInvalidFeeParam);

        // add to list (guarantees that there's only one pool per currency pair)
        list_add<A, B>(list);

        // create pool
        let pool = Pool<A, B> {
            id: object::new(ctx),
            balance_a: init_a,
            balance_b: init_b,
            lp_supply: create_supply(LP<A, B> {}),
            lp_fee_bps,
            admin_fee_pct,
            admin_fee_balance: balance::zero<LP<A, B>>()
        };

        // mint initial lp tokens
        let lp_amt = mulsqrt(balance::value(&pool.balance_a), balance::value(&pool.balance_b));
        let lp_coin = lp_increase_supply(&mut pool, lp_amt, ctx);

        event::emit(PoolCreationEvent { pool_id: object::id(&pool) });
        transfer::share_object(pool);

        lp_coin
    }

    /// Entry function. Creates a new Pool with provided initial balances. Transfers
    /// the initial LP coins to the sender.
    public entry fun create_pool_<A, B>(
        list: &mut PoolList,
        init_a: Coin<A>,
        init_b: Coin<B>,
        lp_fee_bps: u64,
        admin_fee_pct: u64,
        ctx: &mut TxContext,
    ) {
        let lp_coin = create_pool(
            list,
            coin::into_balance(init_a),
            coin::into_balance(init_b),
            lp_fee_bps,
            admin_fee_pct,
            ctx
        );
        transfer::transfer(
            lp_coin,
            tx_context::sender(ctx)
        );
    }

    /// Deposit liquidity into pool. The deposit will use up the maximum amount of
    /// the provided balances possible depending on the current pool ratio. Usually
    /// this means that all of either `input_a` or `input_b` will be fully used, while
    /// the other only partially. Otherwise, both input values will be fully used.
    /// Returns the remaining input amounts (if any) and LPCoin of appropriate value.
    /// Fails if the value of the issued LPCoin is smaller than `min_lp_out`. 
    public fun deposit<A, B>(
        pool: &mut Pool<A, B>,
        input_a: Balance<A>,
        input_b: Balance<B>,
        min_lp_out: u64,
        ctx: &mut TxContext
    ): (Balance<A>, Balance<B>, LPCoin<A, B>) {
        // sanity checks
        assert!(balance::value(&input_a) > 0, EZeroInput);
        assert!(balance::value(&input_b) > 0, EZeroInput);

        // calculate the deposit amounts
        let dab: u128 = (balance::value(&input_a) as u128) * (balance::value(&pool.balance_b) as u128);
        let dba: u128 = (balance::value(&input_b) as u128) * (balance::value(&pool.balance_a) as u128);

        let deposit_a: u64;
        let deposit_b: u64;
        let lp_to_issue: u64;
        if (dab > dba) {
            deposit_b = balance::value(&input_b);
            deposit_a = (ceil_div_u128(
                dba,
                (balance::value(&pool.balance_b) as u128),
            ) as u64);
            lp_to_issue = muldiv(
                deposit_b,
                balance::supply_value(&pool.lp_supply),
                balance::value(&pool.balance_b)
            );
        } else if (dab < dba) {
            deposit_a = balance::value(&input_a);
            deposit_b = (ceil_div_u128(
                dab,
                (balance::value(&pool.balance_a) as u128),
            ) as u64);
            lp_to_issue = muldiv(
                deposit_a,
                balance::supply_value(&pool.lp_supply),
                balance::value(&pool.balance_a)
            );
        } else {
            deposit_a = balance::value(&input_a);
            deposit_b = balance::value(&input_b);
            if (balance::supply_value(&pool.lp_supply) == 0) {
                // in this case both pool balances are 0 and lp supply is 0
                lp_to_issue = mulsqrt(deposit_a, deposit_b);
            } else {
                // the ratio of input a and b matches the ratio of pool balances
                lp_to_issue = muldiv(
                    deposit_a,
                    balance::supply_value(&pool.lp_supply),
                    balance::value(&pool.balance_a)
                );
            }
        };

        // deposit amounts into pool 
        balance::join(
            &mut pool.balance_a,
            balance::split(&mut input_a, deposit_a)
        );
        balance::join(
            &mut pool.balance_b,
            balance::split(&mut input_b, deposit_b)
        );

        // mint lp coin
        assert!(lp_to_issue >= min_lp_out, EExcessiveSlippage);
        let lp_coin = lp_increase_supply(pool, lp_to_issue, ctx);

        // return
        (input_a, input_b, lp_coin)
    }

    /// Entry function. Deposit liquidity into pool. The deposit will use up the maximum
    /// amount of the provided coins possible depending on the current pool ratio. Usually
    /// this means that all of either `input_a` or `input_b` will be fully used, while
    /// the other only partially. Otherwise, both input values will be fully used.
    /// Transfers the remaining input amounts (if any) and LPCoin of appropriate value
    /// to the sender. Fails if the value of the issued LPCoin is smaller than `min_lp_out`. 
    public entry fun deposit_<A, B>(
        pool: &mut Pool<A, B>,
        input_a: Coin<A>,
        input_b: Coin<B>,
        min_lp_out: u64,
        ctx: &mut TxContext
    ) {
        let (remaining_a, remaining_b, lp_coin) = deposit(
            pool, coin::into_balance(input_a), coin::into_balance(input_b), min_lp_out, ctx
        );

        // transfer the output amounts to the caller (if any)
        let sender = tx_context::sender(ctx);
        destroy_or_transfer_balance(remaining_a, sender, ctx);
        destroy_or_transfer_balance(remaining_b, sender, ctx);
        destroy_or_transfer_lp_coin(lp_coin, sender);
    }


    /// Burns the provided LPCoin and withdraws corresponding pool balances.
    /// Fails if the withdrawn balances are smaller than `min_a_out` and `min_b_out`
    /// respectively.
    public fun withdraw<A, B>(
        pool: &mut Pool<A, B>,
        lp_in: LPCoin<A, B>,
        min_a_out: u64,
        min_b_out: u64,
    ): (Balance<A>, Balance<B>) {
        // sanity checks
        assert!(&lp_in.pool_id == object::uid_as_inner(&pool.id), EInvalidPoolID);
        assert!(balance::value(&lp_in.balance) > 0, EZeroInput);

        // calculate output amounts
        let lp_in_value = balance::value(&lp_in.balance);
        let pool_a_value = balance::value(&pool.balance_a);
        let pool_b_value = balance::value(&pool.balance_b);
        let pool_lp_value = balance::supply_value(&pool.lp_supply);

        let a_out = muldiv(lp_in_value, pool_a_value, pool_lp_value);
        let b_out = muldiv(lp_in_value, pool_b_value, pool_lp_value);
        assert!(a_out >= min_a_out, EExcessiveSlippage);
        assert!(b_out >= min_b_out, EExcessiveSlippage);

        // burn lp tokens
        let LPCoin { id, pool_id: _, balance: lp_in_balance } = lp_in;
        object::delete(id);
        balance::decrease_supply(&mut pool.lp_supply, lp_in_balance);

        // return amounts
        (
            balance::split(&mut pool.balance_a, a_out),
            balance::split(&mut pool.balance_b, b_out)
        )
    }

    /// Entry function. Burns the provided LPCoin and withdraws corresponding
    /// pool balances. Fails if the withdrawn balances are smaller than
    /// `min_a_out` and `min_b_out` respectively. Transfers the withdrawn balances
    /// to the sender.
    public entry fun withdraw_<A, B>(
        pool: &mut Pool<A, B>,
        lp_in: LPCoin<A, B>,
        min_a_out: u64,
        min_b_out: u64,
        ctx: &mut TxContext
    ) {
        let (a_out, b_out) = withdraw(pool, lp_in, min_a_out, min_b_out);

        let sender = tx_context::sender(ctx);
        destroy_or_transfer_balance(a_out, sender, ctx);
        destroy_or_transfer_balance(b_out, sender, ctx);
    }

    /// Calclates swap result and fees based on the input amount and current pool state.
    fun calc_swap_result(
        i_value: u64,
        i_pool_value: u64,
        o_pool_value: u64,
        pool_lp_value: u64,
        lp_fee_bps: u64,
        admin_fee_pct: u64
    ): (u64, u64) {
        // calc out value
        let lp_fee_value = ceil_muldiv(i_value, lp_fee_bps, BPS_IN_100_PCT);
        let in_after_lp_fee = i_value - lp_fee_value;
        let out_value = muldiv(in_after_lp_fee, o_pool_value, i_pool_value + in_after_lp_fee);

        // calc admin fee
        let admin_fee_value = muldiv(lp_fee_value, admin_fee_pct, 100);
        // dL = L * sqrt((A + dA) / A) - L = sqrt(L^2(A + dA) / A) - L
        let admin_fee_in_lp = (math::sqrt_u128(
            muldiv_u128(
                (pool_lp_value as u128) * (pool_lp_value as u128),
                ((i_pool_value + i_value) as u128),
                ((i_pool_value + i_value - admin_fee_value) as u128)
            )
        ) as u64) - pool_lp_value;

        (out_value, admin_fee_in_lp)
    }

    /// Swaps the provided amount of A for B. Fails if the resulting amount of B
    /// is smaller than `min_out`.
    public fun swap_a<A, B>(
        pool: &mut Pool<A, B>, input: Balance<A>, min_out: u64,
    ): Balance<B> {
        // sanity checks
        assert!(balance::value(&input) > 0, EZeroInput);
        assert!(
            balance::value(&pool.balance_a) > 0 && balance::value(&pool.balance_b) > 0,
            ENoLiquidity
        );

        // calculate swap result
        let i_value = balance::value(&input);
        let i_pool_value = balance::value(&pool.balance_a);
        let o_pool_value = balance::value(&pool.balance_b);
        let pool_lp_value = balance::supply_value(&pool.lp_supply);

        let (out_value, admin_fee_in_lp) = calc_swap_result(
            i_value, i_pool_value, o_pool_value, pool_lp_value, pool.lp_fee_bps, pool.admin_fee_pct
        );

        assert!(out_value >= min_out, EExcessiveSlippage);

        // deposit admin fee
        balance::join(
            &mut pool.admin_fee_balance,
            balance::increase_supply(&mut pool.lp_supply, admin_fee_in_lp)
        );

        // deposit input
        balance::join(&mut pool.balance_a, input);

        // return output
        balance::split(&mut pool.balance_b, out_value)
    }

    /// Entry function. Swaps the provided amount of A for B. Fails if the resulting
    /// amount of B is smaller than `min_out`. Transfers the resulting Coin to the sender.
    public entry fun swap_a_<A, B>(
        pool: &mut Pool<A, B>, input: Coin<A>, min_out: u64, ctx: &mut TxContext
    ) {
        let out = swap_a(pool, coin::into_balance(input), min_out);
        destroy_or_transfer_balance(out, tx_context::sender(ctx), ctx);
    }

    /// Swaps the provided amount of B for A. Fails if the resulting amount of A
    /// is smaller than `min_out`.
    public fun swap_b<A, B>(
        pool: &mut Pool<A, B>, input: Balance<B>, min_out: u64
    ): Balance<A> {
        // sanity checks
        assert!(balance::value(&input) > 0, EZeroInput);
        assert!(
            balance::value(&pool.balance_a) > 0 && balance::value(&pool.balance_b) > 0,
            ENoLiquidity
        );

        // calculate swap result
        let i_value = balance::value(&input);
        let i_pool_value = balance::value(&pool.balance_b);
        let o_pool_value = balance::value(&pool.balance_a);
        let pool_lp_value = balance::supply_value(&pool.lp_supply);

        let (out_value, admin_fee_in_lp) = calc_swap_result(
            i_value, i_pool_value, o_pool_value, pool_lp_value, pool.lp_fee_bps, pool.admin_fee_pct
        );

        assert!(out_value >= min_out, EExcessiveSlippage);

        // deposit admin fee
        balance::join(
            &mut pool.admin_fee_balance,
            balance::increase_supply(&mut pool.lp_supply, admin_fee_in_lp)
        );

        // deposit input
        balance::join(&mut pool.balance_b, input);

        // return output
        balance::split(&mut pool.balance_a, out_value)
    }

    /// Entry function. Swaps the provided amount of B for A. Fails if the resulting
    /// amount of A is smaller than `min_out`. Transfers the resulting Coin to the sender.
    public entry fun swap_b_<A, B>(
        pool: &mut Pool<A, B>, input: Coin<B>, min_out: u64, ctx: &mut TxContext
    ) {
        let out = swap_b(pool, coin::into_balance(input), min_out);
        destroy_or_transfer_balance(out, tx_context::sender(ctx), ctx);
    }

    /// Withdraw `amount` of collected admin fees by providing pool's PoolAdminCap.
    /// When `amount` is set to 0, it will withdraw all available fees.
    public fun admin_withdraw_fees<A, B>(
        pool: &mut Pool<A, B>,
        _: &AdminCap, 
        amount: u64,
        ctx: &mut TxContext
    ): LPCoin<A, B> {
        if (amount == 0) amount = balance::value(&pool.admin_fee_balance);
        LPCoin {
            id: object::new(ctx),
            pool_id: object::uid_to_inner(&pool.id),
            balance: balance::split(&mut pool.admin_fee_balance, amount)
        }
    }

    /// Entry function. Withdraw `amount` of collected admin fees by providing
    /// pool's PoolAdminCap. When `amount` is set to 0, it will withdraw all
    /// available fees. Transfers the resulting LPCoin to the sender (if any).
    public entry fun admin_withdraw_fees_<A, B>(
        pool: &mut Pool<A, B>,
        admin_cap: &AdminCap,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let lp_coin = admin_withdraw_fees(pool, admin_cap, amount, ctx);
        destroy_or_transfer_lp_coin(lp_coin, tx_context::sender(ctx));
    }

    /* ================= test only ================= */

    #[test_only]
    /// Destroy an `LPCoin` with any value in it for testing purposes.
    public fun lp_coin_destroy_for_testing<A, B>(self: LPCoin<A, B>) {
        let LPCoin {id, pool_id: _, balance} = self;
        object::delete(id);
        balance::destroy_for_testing(balance);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }

    /* ================= tests ================= */

    #[test_only]
    struct BAR has drop {}
    #[test_only]
    struct FOO has drop {}
    #[test_only]
    struct FOOD has drop {}
    #[test_only]
    struct FOOd has drop {}

    #[test]
    fun test_cmp_type() {
        assert!(cmp_type_names(&type_name::get<BAR>(), &type_name::get<FOO>()) == 0, 0);
        assert!(cmp_type_names(&type_name::get<FOO>(), &type_name::get<FOO>()) == 1, 0);
        assert!(cmp_type_names(&type_name::get<FOO>(), &type_name::get<BAR>()) == 2, 0);

        assert!(cmp_type_names(&type_name::get<FOO>(), &type_name::get<FOOd>()) == 0, 0);
        assert!(cmp_type_names(&type_name::get<FOOd>(), &type_name::get<FOO>()) == 2, 0);

        assert!(cmp_type_names(&type_name::get<FOOD>(), &type_name::get<FOOd>()) == 0, 0);
        assert!(cmp_type_names(&type_name::get<FOOd>(), &type_name::get<FOOD>()) == 2, 0);
    }

    #[test_only]
    fun destroy_empty_for_testing(list: PoolList) {
        let PoolList { id, table } = list;
        object::delete(id);
        table::destroy_empty(table);
    }

    #[test_only]
    fun remove_for_testing<A, B>(list: &mut PoolList) {
        let a = type_name::get<A>();
        let b = type_name::get<B>();
        table::remove(&mut list.table, PoolListItem{ a, b });
    }

    #[test]
    fun test_pool_list_add() {
        let ctx = &mut tx_context::dummy();
        let list = empty_list(ctx);

        list_add<BAR, FOO>(&mut list);
        list_add<FOO, FOOd>(&mut list);

        remove_for_testing<BAR, FOO>(&mut list);
        remove_for_testing<FOO, FOOd>(&mut list);
        destroy_empty_for_testing(list);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidPair)]
    fun test_pool_list_add_aborts_when_wrong_order() {
        let ctx = &mut tx_context::dummy();
        let list = empty_list(ctx);

        list_add<FOO, BAR>(&mut list);

        remove_for_testing<FOO, BAR>(&mut list);
        destroy_empty_for_testing(list);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidPair)]
    fun test_pool_list_add_aborts_when_equal() {
        let ctx = &mut tx_context::dummy();
        let list = empty_list(ctx);

        list_add<FOO, FOO>(&mut list);

        remove_for_testing<FOO, FOO>(&mut list);
        destroy_empty_for_testing(list);
    }

    #[test]
    #[expected_failure(abort_code = EPoolAlreadyExists)]
    fun test_pool_list_add_aborts_when_already_exists() {
        let ctx = &mut tx_context::dummy();
        let list = empty_list(ctx);

        list_add<BAR, FOO>(&mut list);
        list_add<BAR, FOO>(&mut list); // aborts here

        remove_for_testing<BAR, FOO>(&mut list);
        destroy_empty_for_testing(list);
    }
}
