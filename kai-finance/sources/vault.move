module kai::vault {
    use std::option::{Self, Option};
    use std::vector;
    use sui::tx_context::TxContext;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, TreasuryCap};
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::clock::Clock;
    use sui::vec_map::{Self, VecMap};
    use sui::vec_set;
    use sui::math;
    use sui::event;

    use kai::time_locked_balance::{Self as tlb, TimeLockedBalance};
    use kai::util::{muldiv, timestamp_sec};
   
    friend kai::ywhusdce;
    friend kai::scallop_whusdce;

    friend kai::ywhusdte; // deprecated
    friend kai::scallop_whusdte; // deprecated
    friend kai::ysui; // deprecated
    friend kai::scallop_sui; // deprecated

    /* ================= constants ================= */

    const MODULE_VERSION: u64 = 1; 

    const BPS_IN_100_PCT: u64 = 10000;

    const DEFAULT_PROFIT_UNLOCK_DURATION_SEC: u64 = 100 * 60; // 100 minutes

    /* ================= errors ================= */

    /// BPS value can be at most 10000 (100%)
    const EInvalidBPS: u64 = 0;

    /// Deposit is over vault's TVL cap
    const EDepositTooLarge: u64 = 1;

    /// A withdraw ticket is issued
    const EWithdrawTicketIssued: u64 = 2;

    /// Input balance amount should be positive
    const EZeroAmount: u64 = 3;

    /// Strategy has already withdrawn into the ticket
    const EStrategyAlreadyWithdrawn: u64 = 4;

    /// All strategies need to be withdrawn from to claim the ticket
    const EStrategyNotWithdrawn: u64 = 5;

    /// The strategy is not registered with the vault
    const EInvalidVaultAccess: u64 = 6;

    /// Target strategy weights should add up to 100%
    const EInvalidWeights: u64 = 7;

    /// An invariant has been violated
    const EInvariantViolation: u64 = 8;

    /// Calling functions from the wrong package version
    const EWrongVersion: u64 = 9;

    /// Migration is not an upgrade
    const ENotUpgrade: u64 = 10;

    /* ================= events ================= */

    struct DepositEvent<phantom YT> has copy, drop {
        amount: u64,
        lp_minted: u64,
    }

    struct WithdrawEvent<phantom YT> has copy, drop {
        amount: u64,
        lp_burned: u64,
    }

    struct StrategyProfitEvent<phantom YT> has copy, drop {
        strategy_id: ID,
        profit: u64,
        fee_amt_yt: u64,
    }

    struct StrategyLossEvent<phantom YT> has copy, drop {
        strategy_id: ID,
        to_withdraw: u64,
        withdrawn: u64
    }

    /* ================= AdminCap ================= */

    /// There can only ever be one `AdminCap` for a `Vault`
    struct AdminCap<phantom YT> has key, store {
        id: UID,
    }

    /* ================= VaultAccess ================= */

    /// Strategies store this and it gives them access to deposit and withdraw
    /// from the vault
    struct VaultAccess has store {
        id: UID,
    }

    public(friend) fun vault_access_id(access: &VaultAccess): ID {
        object::uid_to_inner(&access.id)
    }

    /* ================= StrategyRemovalTicket ================= */

    struct StrategyRemovalTicket<phantom T, phantom YT> {
        access: VaultAccess,
        returned_balance: Balance<T>,
    }

    public(friend) fun new_strategy_removal_ticket<T, YT>(
        access: VaultAccess, returned_balance: Balance<T>
    ): StrategyRemovalTicket<T, YT> {
        StrategyRemovalTicket {
            access,
            returned_balance,
        }
    }

    /* ================= WithdrawTicket ================= */

    struct StrategyWithdrawInfo<phantom T> has store {
        to_withdraw: u64,
        withdrawn_balance: Balance<T>,
        has_withdrawn: bool,
    }

    struct WithdrawTicket<phantom T, phantom YT> {
        to_withdraw_from_free_balance: u64,
        strategy_infos: VecMap<ID, StrategyWithdrawInfo<T>>,
        lp_to_burn: Balance<YT>,
    }

    public(friend) fun withdraw_ticket_to_withdraw<T, YT>(
        ticket: &WithdrawTicket<T, YT>, access: &VaultAccess
    ): u64 {
        let id = object::uid_as_inner(&access.id);
        let info = vec_map::get(&ticket.strategy_infos, id);
        info.to_withdraw
    }

    /* ================= RebalanceInfo ================= */

    struct RebalanceInfo has store, copy, drop {
        /// The target amount the strategy should repay. The strategy shouldn't
        /// repay more than this amount.
        to_repay: u64,
        /// The target amount the strategy should borrow. There's no guarantee
        /// though that this amount is available in vault's free balance. The
        /// strategy shouldn't borrow more than this amount.
        can_borrow: u64,
    }

    struct RebalanceAmounts has copy, drop {
        inner: VecMap<ID, RebalanceInfo>,
    } 

    public(friend) fun rebalance_amounts_get(
        amounts: &RebalanceAmounts, access: &VaultAccess
    ): (u64, u64) {
        let strategy_id = object::uid_as_inner(&access.id);
        let amts = vec_map::get(&amounts.inner, strategy_id);
        (amts.can_borrow, amts.to_repay)
    }

    /* ================= StrategyState ================= */

    struct StrategyState has store {
        borrowed: u64,
        target_alloc_weight_bps: u64,
        max_borrow: Option<u64>,
    }

    /* ================= Vault ================= */

    struct Vault<phantom T, phantom YT> has key {
        id: UID,
        /// balance that's not allocated to any strategy
        free_balance: Balance<T>,
        /// slowly distribute profits over time to avoid sandwitch attacks on rebalance
        time_locked_profit: TimeLockedBalance<T>,
        /// treasury of the vault's yield-bearing token
        lp_treasury: TreasuryCap<YT>,
        /// strategies
        strategies: VecMap<ID, StrategyState>,
        /// performance fee balance
        performance_fee_balance: Balance<YT>,
        /// priority order for withdrawing from strategies
        strategy_withdraw_priority_order: vector<ID>,
        /// only one withdraw ticket can be active at a time
        withdraw_ticket_issued: bool,

        /// deposits are disabled above this threshold
        tvl_cap: Option<u64>,
        /// duration of profit unlock in seconds
        profit_unlock_duration_sec: u64,
        /// performance fee in basis points (taken from all profits)
        performance_fee_bps: u64,

        version: u64,
    }

    public(friend) fun new<T, YT>(
        lp_treasury: TreasuryCap<YT>, ctx: &mut TxContext
    ): AdminCap<YT> {
        let vault = Vault<T, YT> {
            id: object::new(ctx),

            free_balance: balance::zero(),
            time_locked_profit: tlb::create(balance::zero(), 0, 0),
            lp_treasury, 
            strategies: vec_map::empty(),
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order: vector::empty(),
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        transfer::share_object(vault);

        // since there can be only one `TreasuryCap<YT>` for type `YT`, there can be only
        // one `Vault<T, YT>` and `AdminCap<YT>` for type `YT` as well.
        let admin_cap = AdminCap<YT> {
            id: object::new(ctx),
        };
        admin_cap
    }

    fun assert_version<T, YT>(vault: &Vault<T, YT>) {
        assert!(vault.version == MODULE_VERSION, EWrongVersion);
    }

    /* ================= read ================= */

    public fun free_balance<T, YT>(vault: &Vault<T, YT>): u64 {
        balance::value(&vault.free_balance)
    }

    public fun tvl_cap<T, YT>(vault: &Vault<T, YT>): Option<u64> {
        vault.tvl_cap
    }

    public fun total_available_balance<T, YT>(vault: &Vault<T, YT>, clock: &Clock): u64 {
        let total: u64 = 0;

        total = total + balance::value(&vault.free_balance);
        total = total + tlb::max_withdrawable(&vault.time_locked_profit, clock);

        let i = 0;
        let n = vec_map::size(&vault.strategies);
        while (i < n) {
            let (_, strategy_state) = vec_map::get_entry_by_idx(&vault.strategies, i);
            total = total + strategy_state.borrowed;
            i = i + 1;
        };

        total
    }

    /* ================= admin ================= */

    entry fun set_tvl_cap<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, tvl_cap: Option<u64>
    ) {
        assert_version(vault);
        vault.tvl_cap = tvl_cap;
    }

    entry fun set_profit_unlock_duration_sec<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, profit_unlock_duration_sec: u64
    ) {
        assert_version(vault);
        vault.profit_unlock_duration_sec = profit_unlock_duration_sec;
    }

    entry fun set_performance_fee_bps<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, performance_fee_bps: u64
    ) {
        assert_version(vault);
        assert!(performance_fee_bps <= BPS_IN_100_PCT, EInvalidBPS);
        vault.performance_fee_bps = performance_fee_bps;
    }

    public fun withdraw_performance_fee<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, amount: u64
    ): Balance<YT> {
        assert_version(vault);
        balance::split(&mut vault.performance_fee_balance, amount)
    }

    entry fun pull_unlocked_profits_to_free_balance<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, clock: &Clock
    ) {
        assert_version(vault);
        balance::join(
            &mut vault.free_balance,
            tlb::withdraw_all(&mut vault.time_locked_profit, clock),
        );
    }

    public(friend) fun add_strategy<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, ctx: &mut TxContext
    ): VaultAccess {
        assert_version(vault);

        let access = VaultAccess { id: object::new(ctx) };
        let strategy_id = object::uid_to_inner(&access.id);

        let target_alloc_weight_bps = if (vec_map::size(&vault.strategies) == 0) {
            BPS_IN_100_PCT
        } else {
            0
        };

        vec_map::insert(
            &mut vault.strategies,
            strategy_id,
            StrategyState {
                borrowed: 0,
                target_alloc_weight_bps,
                max_borrow: option::none(),
            },
        );
        vector::push_back(&mut vault.strategy_withdraw_priority_order, strategy_id);

        access
    }

    entry fun set_strategy_max_borrow<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, strategy_id: ID, max_borrow: Option<u64>
    ) {
        assert_version(vault);

        let state = vec_map::get_mut(&mut vault.strategies, &strategy_id);
        state.max_borrow = max_borrow;
    }

    entry fun set_strategy_target_alloc_weights_bps<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, ids: vector<ID>, weights_bps: vector<u64>
    ) {
        assert_version(vault);

        let ids_seen = vec_set::empty<ID>();
        let total_bps = 0;

        let i = 0;
        let n = vec_map::size(&vault.strategies);
        while (i < n) {
            let id = *vector::borrow(&ids, i);
            let weight = *vector::borrow(&weights_bps, i);
            vec_set::insert(&mut ids_seen, id); // checks for duplicate ids
            total_bps = total_bps + weight;

            let state = vec_map::get_mut(&mut vault.strategies, &id);
            state.target_alloc_weight_bps = weight;

            i = i + 1;
        };

        assert!(total_bps == BPS_IN_100_PCT, EInvalidWeights);
    }

    public fun remove_strategy<T, YT>(
        cap: &AdminCap<YT>, vault: &mut Vault<T, YT>, ticket: StrategyRemovalTicket<T, YT>,
        ids_for_weights: vector<ID>, weights_bps: vector<u64>,
        clock: &Clock
    ) {
        assert_version(vault);

        let StrategyRemovalTicket { access, returned_balance } = ticket;

        let VaultAccess{ id: uid } = access;
        let id = &object::uid_to_inner(&uid);
        object::delete(uid);

        // remove from strategies and return balance
        let (_, state) = vec_map::remove(&mut vault.strategies, id);
        let StrategyState { borrowed, target_alloc_weight_bps: _, max_borrow: _ } = state;

        let returned_value = balance::value(&returned_balance);
        if (returned_value > borrowed) {
            let profit = balance::split(
                &mut returned_balance,
                returned_value - borrowed
            );
            tlb::top_up(&mut vault.time_locked_profit, profit, clock);
        };
        balance::join(&mut vault.free_balance, returned_balance);

        // remove from withdraw priority order
        let (has, idx) = vector::index_of(&vault.strategy_withdraw_priority_order, id);
        assert!(has, EInvariantViolation);
        vector::remove(&mut vault.strategy_withdraw_priority_order, idx);

        // set new weights
        set_strategy_target_alloc_weights_bps(cap, vault, ids_for_weights, weights_bps);
    }

    entry fun migrate<T, YT>(
        _cap: &AdminCap<YT>, vault: &mut Vault<T, YT>
    ) {
        assert!(vault.version < MODULE_VERSION, ENotUpgrade);
        vault.version = MODULE_VERSION;
    }

    /* ================= user operations ================= */

    public fun deposit<T, YT>(
        vault: &mut Vault<T, YT>, balance: Balance<T>, clock: &Clock
    ): Balance<YT> {
        assert_version(vault);
        assert!(vault.withdraw_ticket_issued == false, EWithdrawTicketIssued);
        if (balance::value(&balance) == 0) {
            balance::destroy_zero(balance);
            return balance::zero()
        };

        // edge case -- appropriate any existing balances into performance
        // fees in case lp supply is 0.
        // this guarantees that lp supply is non-zero if total_available_balance
        // is positive. 
        if (coin::total_supply(&vault.lp_treasury) == 0) {
            // take any existing balances from time_locked_profit
            tlb::change_unlock_per_second(
                &mut vault.time_locked_profit, 0, clock
            );
            let skimmed = tlb::skim_extraneous_balance(&mut vault.time_locked_profit);
            let withdrawn = tlb::withdraw_all(&mut vault.time_locked_profit, clock);
            balance::join(&mut vault.free_balance, skimmed);
            balance::join(&mut vault.free_balance, withdrawn);

            // appropriate everything to performance fees
            let total_available_balance = total_available_balance(vault, clock);
            balance::join(
                &mut vault.performance_fee_balance,
                coin::mint_balance(&mut vault.lp_treasury, total_available_balance)
            );
        };

        let total_available_balance = total_available_balance(vault, clock);
        if (option::is_some(&vault.tvl_cap)) {
            let tvl_cap = *option::borrow(&vault.tvl_cap);
            assert!(
                total_available_balance + balance::value(&balance) <= tvl_cap,
                EDepositTooLarge
            );
        };

        let lp_amount = if (total_available_balance == 0) {
            balance::value(&balance)
        } else {
            muldiv(
                coin::total_supply(&vault.lp_treasury),
                balance::value(&balance),
                total_available_balance
            )
        };

        event::emit(DepositEvent<YT> {
            amount: balance::value(&balance),
            lp_minted: lp_amount,
        });

        balance::join(&mut vault.free_balance, balance);
        coin::mint_balance(&mut vault.lp_treasury, lp_amount)
    }

    fun create_withdraw_ticket<T, YT>(vault: &Vault<T, YT>): WithdrawTicket<T, YT> {
        let strategy_infos: VecMap<ID, StrategyWithdrawInfo<T>> = vec_map::empty();
        let i = 0;
        let n = vector::length(&vault.strategy_withdraw_priority_order);
        while (i < n) {
            let strategy_id = *vector::borrow(&vault.strategy_withdraw_priority_order, i);
            let info = StrategyWithdrawInfo {
                to_withdraw: 0,
                withdrawn_balance: balance::zero(),
                has_withdrawn: false,
            };
            vec_map::insert(&mut strategy_infos, strategy_id, info);

            i = i + 1;
        };

        WithdrawTicket {
            to_withdraw_from_free_balance: 0,
            strategy_infos,
            lp_to_burn: balance::zero(),
        }
    }


    public fun withdraw<T, YT>(
        vault: &mut Vault<T, YT>, balance: Balance<YT>, clock: &Clock
    ): WithdrawTicket<T, YT> {
        assert_version(vault);
        assert!(vault.withdraw_ticket_issued == false, EWithdrawTicketIssued);
        assert!(balance::value(&balance) > 0, EZeroAmount);
        vault.withdraw_ticket_issued = true;

        let ticket = create_withdraw_ticket(vault);
        balance::join(&mut ticket.lp_to_burn, balance);

        // join unlocked profits to free balance
        balance::join(
            &mut vault.free_balance,
            tlb::withdraw_all(&mut vault.time_locked_profit, clock),
        );

        // calculate withdraw amount
        let total_available = total_available_balance(vault, clock);
        let remaining_to_withdraw = muldiv(
            balance::value(&ticket.lp_to_burn),
            total_available,
            coin::total_supply(&vault.lp_treasury)
        );

        // first withdraw everything possible from free balance
        ticket.to_withdraw_from_free_balance = math::min(
            remaining_to_withdraw,
            balance::value(&vault.free_balance)
        );
        remaining_to_withdraw = remaining_to_withdraw - ticket.to_withdraw_from_free_balance;

        if (remaining_to_withdraw == 0) {
            return ticket
        };

        // if this is not enough, start withdrawing from strategies
        // first withdraw from all the strategies that are over their target allocation
        let total_borrowed_after_excess_withdrawn = 0;
        let i = 0;
        let n = vector::length(&vault.strategy_withdraw_priority_order);
        while (i < n) {
            let strategy_id = vector::borrow(&vault.strategy_withdraw_priority_order, i);
            let strategy_state = vec_map::get(&vault.strategies, strategy_id);
            let strategy_withdraw_info = vec_map::get_mut(&mut ticket.strategy_infos, strategy_id);

            let over_cap = if (option::is_some(&strategy_state.max_borrow)) {
                let max_borrow: u64 = *option::borrow(&strategy_state.max_borrow);
                if (strategy_state.borrowed > max_borrow) {
                    strategy_state.borrowed - max_borrow
                } else {
                    0
                }
            } else {
                0
            };
            let to_withdraw = if (over_cap >= remaining_to_withdraw) {
                remaining_to_withdraw
            } else {
                over_cap
            };
            remaining_to_withdraw = remaining_to_withdraw - to_withdraw;
            total_borrowed_after_excess_withdrawn =
                total_borrowed_after_excess_withdrawn + strategy_state.borrowed - to_withdraw;

            strategy_withdraw_info.to_withdraw = to_withdraw;

            i = i + 1;
        };

        // if that is not enough, withdraw from all strategies proportionally so that
        // the strategy borrowed amounts are kept at the same proportions as they were before
        if (remaining_to_withdraw == 0) {
            return ticket
        };
        let to_withdraw_propotionally_base = remaining_to_withdraw;

        let i = 0;
        let n = vector::length(&vault.strategy_withdraw_priority_order);
        while (i < n) {
            let strategy_id = vector::borrow(&vault.strategy_withdraw_priority_order, i);
            let strategy_state = vec_map::get(&vault.strategies, strategy_id);
            let strategy_withdraw_info = vec_map::get_mut(&mut ticket.strategy_infos, strategy_id);

            let strategy_remaining = strategy_state.borrowed - strategy_withdraw_info.to_withdraw;
            let to_withdraw = muldiv(
                strategy_remaining,
                to_withdraw_propotionally_base,
                total_borrowed_after_excess_withdrawn
            );

            strategy_withdraw_info.to_withdraw = strategy_withdraw_info.to_withdraw + to_withdraw;
            remaining_to_withdraw = remaining_to_withdraw - to_withdraw;

            i = i + 1;
        };

        // if that is not enough, start withdrawing all from strategies in priority order
        if (remaining_to_withdraw == 0) {
            return ticket
        };

        let i = 0;
        let n = vector::length(&vault.strategy_withdraw_priority_order);
        while (i < n) {
            let strategy_id = vector::borrow(&vault.strategy_withdraw_priority_order, i);
            let strategy_state = vec_map::get(&vault.strategies, strategy_id);
            let strategy_withdraw_info = vec_map::get_mut(&mut ticket.strategy_infos, strategy_id);

            let strategy_remaining = strategy_state.borrowed - strategy_withdraw_info.to_withdraw;
            let to_withdraw = math::min(strategy_remaining, remaining_to_withdraw);

            strategy_withdraw_info.to_withdraw = strategy_withdraw_info.to_withdraw + to_withdraw;
            remaining_to_withdraw = remaining_to_withdraw - to_withdraw;

            if (remaining_to_withdraw == 0) {
                break
            };

            i = i + 1;
        };

        ticket
    }

    public fun redeem_withdraw_ticket<T, YT>(
        vault: &mut Vault<T, YT>, ticket: WithdrawTicket<T, YT>
    ): Balance<T> {
        assert_version(vault);

        let out = balance::zero();

        let WithdrawTicket {
            to_withdraw_from_free_balance, strategy_infos, lp_to_burn
        } = ticket;
        let lp_to_burn_amt = balance::value(&lp_to_burn);

        while (vec_map::size(&strategy_infos) > 0) {
            let (strategy_id, withdraw_info) = vec_map::pop(&mut strategy_infos);
            let StrategyWithdrawInfo {
                to_withdraw, withdrawn_balance, has_withdrawn
            } = withdraw_info;
            if (to_withdraw > 0) {
                assert!(has_withdrawn, EStrategyNotWithdrawn);
            };

            if (balance::value(&withdrawn_balance) < to_withdraw) {
                event::emit(StrategyLossEvent<YT> {
                    strategy_id,
                    to_withdraw,
                    withdrawn: balance::value(&withdrawn_balance),
                });
            };

            // Reduce strategy's borrowed amount. This calculation is intentionally based on
            // `to_withdraw` and not `withdrawn_balance` amount so that any losses generated
            // by the withdrawal are effectively covered by the user and considered paid back
            // to the vault. This also ensures that vault's `total_available_balance` before
            // and after withdrawal matches the amount of lp tokens burned.
            let strategy_state = vec_map::get_mut(&mut vault.strategies, &strategy_id);
            strategy_state.borrowed = strategy_state.borrowed - to_withdraw;

            balance::join(&mut out, withdrawn_balance);
        };
        vec_map::destroy_empty(strategy_infos);

        balance::join(
            &mut out,
            balance::split(&mut vault.free_balance, to_withdraw_from_free_balance),
        );
        balance::decrease_supply(
            coin::supply_mut(&mut vault.lp_treasury),
            lp_to_burn,
        );

        event::emit(WithdrawEvent<YT> {
            amount: balance::value(&out),
            lp_burned: lp_to_burn_amt,
        });

        vault.withdraw_ticket_issued = false;
        out
    }

    /* ================= strategy operations ================= */

    /// Makes the strategy deposit the withdrawn balance into the `WithdrawTicket`.
    public(friend) fun strategy_withdraw_to_ticket<T, YT>(
        ticket: &mut WithdrawTicket<T, YT>, access: &VaultAccess, balance: Balance<T>
    ) {
        let strategy_id = object::uid_as_inner(&access.id);
        let withdraw_info = vec_map::get_mut(&mut ticket.strategy_infos, strategy_id);

        assert!(withdraw_info.has_withdrawn == false, EStrategyAlreadyWithdrawn);
        withdraw_info.has_withdrawn = true;

        balance::join(&mut withdraw_info.withdrawn_balance, balance);
    }

    /// Get the target rebalance amounts the strategies should repay or can borrow.
    /// It takes into account strategy target allocation weights and max borrow limits
    /// and calculates the values so that the vault's balance allocations are kept
    /// at the target weights and all of the vault's balance is allocated.
    /// This function is idempotent in the sense that if you rebalance the pool with
    /// the returned amounts and call it again, the result will require no further
    /// rebalancing.
    /// The strategies are not expected to repay / borrow the exact amounts suggested
    /// as this may be dictated by their internal logic, but they should try to
    /// get as close as possible. Since the strategies are trusted, there are no
    /// explicit checks for this within the vault.
    public fun calc_rebalance_amounts<T, YT>(
        vault: &Vault<T, YT>, clock: &Clock
    ): RebalanceAmounts {
        assert!(vault.withdraw_ticket_issued == false, EWithdrawTicketIssued);

        // calculate total available balance and prepare rebalance infos
        let rebalance_infos: VecMap<ID, RebalanceInfo> = vec_map::empty();
        let total_available_balance = 0;
        let max_borrow_idxs_to_process = vector::empty();
        let no_max_borrow_idxs = vector::empty();

        total_available_balance = total_available_balance + balance::value(&vault.free_balance);
        total_available_balance = total_available_balance + tlb::max_withdrawable(&vault.time_locked_profit, clock);

        let i = 0;
        let n = vec_map::size(&vault.strategies);
        while (i < n) {
            let (strategy_id, strategy_state) = vec_map::get_entry_by_idx(&vault.strategies, i);
            vec_map::insert(
                &mut rebalance_infos,
                *strategy_id,
                RebalanceInfo {
                    to_repay: 0,
                    can_borrow: 0,
                },
            );

            total_available_balance = total_available_balance + strategy_state.borrowed;
            if (option::is_some(&strategy_state.max_borrow)) {
                vector::push_back(&mut max_borrow_idxs_to_process, i);
            } else {
                vector::push_back(&mut no_max_borrow_idxs, i);
            };

            i = i + 1;
        };

        // process strategies with max borrow limits iteratively until all who can
        // reach their cap have reached it
        let remaining_to_allocate = total_available_balance;
        let remaining_total_alloc_bps = BPS_IN_100_PCT;

        let need_to_reprocess = true;
        while (need_to_reprocess) {
            let i = 0;
            let n = vector::length(&max_borrow_idxs_to_process);
            let new_max_borrow_idxs_to_process = vector::empty();
            need_to_reprocess = false;
            while (i < n) {
                let idx = *vector::borrow(&max_borrow_idxs_to_process, i);
                let (_, strategy_state) = vec_map::get_entry_by_idx(&vault.strategies, idx);
                let (_, rebalance_info) = vec_map::get_entry_by_idx_mut(&mut rebalance_infos, idx);

                let max_borrow: u64 = *option::borrow(&strategy_state.max_borrow);
                let target_alloc_amt = muldiv(
                    remaining_to_allocate,
                    strategy_state.target_alloc_weight_bps,
                    remaining_total_alloc_bps,
                );

                if (target_alloc_amt <= strategy_state.borrowed || max_borrow <= strategy_state.borrowed) {
                    // needs to repay
                    if (target_alloc_amt < max_borrow) {
                        vector::push_back(&mut new_max_borrow_idxs_to_process, idx);
                    } else {
                        let target_alloc_amt = max_borrow;
                        rebalance_info.to_repay = strategy_state.borrowed - target_alloc_amt;
                        remaining_to_allocate = remaining_to_allocate - target_alloc_amt;
                        remaining_total_alloc_bps = remaining_total_alloc_bps - strategy_state.target_alloc_weight_bps;

                        // might add extra amounts to allocate so need to reprocess ones which
                        // haven't reached their cap
                        need_to_reprocess = true; 
                    };

                    i = i + 1;
                    continue
                };
                // can borrow
                if (target_alloc_amt >= max_borrow) {
                    let target_alloc_amt = max_borrow;
                    rebalance_info.can_borrow = target_alloc_amt - strategy_state.borrowed;
                    remaining_to_allocate = remaining_to_allocate - target_alloc_amt;
                    remaining_total_alloc_bps = remaining_total_alloc_bps - strategy_state.target_alloc_weight_bps;

                    // might add extra amounts to allocate so need to reprocess ones which
                    // haven't reached their cap
                    need_to_reprocess = true;

                    i = i + 1;
                    continue
                } else {
                    vector::push_back(&mut new_max_borrow_idxs_to_process, idx);

                    i = i + 1;
                    continue
                }
            };
            max_borrow_idxs_to_process = new_max_borrow_idxs_to_process;
        };

        // the remaining strategies in `max_borrow_idxs_to_process` and `no_max_borrow_idxs` won't reach
        // their cap so we can easilly calculate the remaining amounts to allocate
        let i = 0;
        let n = vector::length(&max_borrow_idxs_to_process);
        while (i < n) {
            let idx = *vector::borrow(&max_borrow_idxs_to_process, i);
            let (_, strategy_state) = vec_map::get_entry_by_idx(&vault.strategies, idx);
            let (_, rebalance_info) = vec_map::get_entry_by_idx_mut(&mut rebalance_infos, idx);

            let target_borrow = muldiv(
                remaining_to_allocate,
                strategy_state.target_alloc_weight_bps,
                remaining_total_alloc_bps,
            );
            if (target_borrow >= strategy_state.borrowed) {
                rebalance_info.can_borrow = target_borrow - strategy_state.borrowed;
            } else {
                rebalance_info.to_repay = strategy_state.borrowed - target_borrow;
            };

            i = i + 1;
        };

        let i = 0;
        let n = vector::length(&no_max_borrow_idxs);
        while (i < n) {
            let idx = *vector::borrow(&no_max_borrow_idxs, i);
            let (_, strategy_state) = vec_map::get_entry_by_idx(&vault.strategies, idx);
            let (_, rebalance_info) = vec_map::get_entry_by_idx_mut(&mut rebalance_infos, idx);

            let target_borrow = muldiv(
                remaining_to_allocate,
                strategy_state.target_alloc_weight_bps,
                remaining_total_alloc_bps,
            );
            if (target_borrow >= strategy_state.borrowed) {
                rebalance_info.can_borrow = target_borrow - strategy_state.borrowed;
            } else {
                rebalance_info.to_repay = strategy_state.borrowed - target_borrow;
            };

            i = i + 1;
        };

        RebalanceAmounts { inner: rebalance_infos }
    }

    /// Strategies call this to repay loaned amounts.
    public(friend) fun strategy_repay<T, YT>(
        vault: &mut Vault<T, YT>, access: &VaultAccess, balance: Balance<T>
    ) {
        assert_version(vault);
        assert!(vault.withdraw_ticket_issued == false, EWithdrawTicketIssued);

        // amounts are purposefully not checked here because the strategies
        // are trusted to repay the correct amounts based on `RebalanceInfo`.
        let strategy_id = object::uid_as_inner(&access.id);
        let strategy_state = vec_map::get_mut(&mut vault.strategies, strategy_id);
        strategy_state.borrowed = strategy_state.borrowed - balance::value(&balance);
        balance::join(&mut vault.free_balance, balance);
    }

    /// Strategies call this to borrow additional funds from the vault. Always returns
    /// exact amount requested or aborts.
    public(friend) fun strategy_borrow<T, YT>(
        vault: &mut Vault<T, YT>, access: &VaultAccess, amount: u64
    ): Balance<T> {
        assert_version(vault);
        assert!(vault.withdraw_ticket_issued == false, EWithdrawTicketIssued);

        // amounts are purpusfully not checked here because the strategies
        // are trusted to borrow the correct amounts based on `RebalanceInfo`.
        let strategy_id = object::uid_as_inner(&access.id);
        let strategy_state = vec_map::get_mut(&mut vault.strategies, strategy_id);
        let balance = balance::split(&mut vault.free_balance, amount);
        strategy_state.borrowed = strategy_state.borrowed + amount;

        balance
    }

    public(friend) fun strategy_hand_over_profit<T, YT>(
        vault: &mut Vault<T, YT>, access: &VaultAccess, profit: Balance<T>, clock: &Clock
    ) {
        assert_version(vault);
        assert!(vault.withdraw_ticket_issued == false, EWithdrawTicketIssued);
        let strategy_id = object::uid_as_inner(&access.id);
        assert!(vec_map::contains(&vault.strategies, strategy_id), EInvalidVaultAccess);

        // collect performance fee
        let fee_amt_t = muldiv(
            balance::value(&profit),
            vault.performance_fee_bps,
            BPS_IN_100_PCT
        );
        let fee_amt_yt = if (fee_amt_t > 0) {
            let total_available_balance = total_available_balance(vault, clock);
            // dL = L * f / (A - f)
            let fee_amt_yt = muldiv(
                coin::total_supply(&vault.lp_treasury),
                fee_amt_t,
                total_available_balance - fee_amt_t
            );
            let fee_yt = coin::mint_balance(&mut vault.lp_treasury, fee_amt_yt);
            balance::join(&mut vault.performance_fee_balance, fee_yt);

            fee_amt_yt
        } else {
            0
        };

        event::emit(StrategyProfitEvent<YT> {
            strategy_id: object::uid_to_inner(&access.id),
            profit: balance::value(&profit),
            fee_amt_yt: fee_amt_yt,
        });

        // reset profit unlock
        balance::join(
            &mut vault.free_balance,
            tlb::withdraw_all(&mut vault.time_locked_profit, clock),
        );

        tlb::change_unlock_per_second(&mut vault.time_locked_profit, 0, clock);
        let redeposit = tlb::skim_extraneous_balance(&mut vault.time_locked_profit);
        balance::join(&mut redeposit, profit);

        tlb::change_unlock_start_ts_sec(
            &mut vault.time_locked_profit, timestamp_sec(clock), clock
        );
        let unlock_per_second = math::divide_and_round_up(
            balance::value(&redeposit),
            vault.profit_unlock_duration_sec
        );
        tlb::change_unlock_per_second(
            &mut vault.time_locked_profit, unlock_per_second, clock
        );
        tlb::top_up(&mut vault.time_locked_profit, redeposit, clock);
    }




    /* =================================================== tests =================================================== */

    #[test_only]
    use sui::coin::{CoinMetadata};
    #[test_only]
    use sui::tx_context;
    #[test_only]
    use sui::clock;
    #[test_only]
    use sui::vec_set::{VecSet};
    #[test_only]
    struct A has drop {}
    #[test_only]
    struct VAULT has drop {}

    #[test_only]
    fun create_a_treasury(ctx: &mut TxContext): (TreasuryCap<VAULT>, CoinMetadata<VAULT>) {
        coin::create_currency(VAULT{}, 6, b"ywhUSDC.e", b"", b"", option::none(), ctx)
    }

    #[test_only]
    fun mint_a_balance(amount: u64): Balance<A> {
        let supply = balance::create_supply(A{});
        let balance = balance::increase_supply(&mut supply, amount);
        sui::test_utils::destroy(supply);
        balance
    }

    #[test]
    fun test_total_available_balance() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, object::id_from_address(@0xA), StrategyState {
            borrowed: 100,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, object::id_from_address(@0xB), StrategyState {
            borrowed: 50,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, object::id_from_address(@0xA));
        vector::push_back(&mut strategy_withdraw_priority_order, object::id_from_address(@0xB));

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(10),
            time_locked_profit: tlb::create(mint_a_balance(200), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 100 * 1000);
        assert!(total_available_balance(&vault, &clock) == 260, 0);

        sui::test_utils::destroy(meta);
        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(clock);
    }

    #[test_only]
    fun assert_ticket_values<T, TY>(
        ticket: &WithdrawTicket<T, TY>,
        to_withdraw_from_free_balance: u64,
        keys: vector<ID>,
        to_withdraw_values: vector<u64>,
        lp_to_burn_amount: u64,
    ) {
        assert!(vector::length(&keys) == vector::length(&to_withdraw_values), 0);
        assert!(ticket.to_withdraw_from_free_balance == to_withdraw_from_free_balance, 0);
        let seen: VecSet<ID> = vec_set::empty();
        let i = 0;
        let n = vector::length(&keys);
        while (i < n) {
            let strategy_id = *vector::borrow(&keys, i);
            vec_set::insert(&mut seen, strategy_id);
            let strategy_withdraw_info = vec_map::get(&ticket.strategy_infos, &strategy_id);
            assert!(strategy_withdraw_info.to_withdraw == *vector::borrow(&to_withdraw_values, i), 0);
            i = i + 1;
        };
        assert!(balance::value(&ticket.lp_to_burn) == lp_to_burn_amount, 0);
    }

    #[test_only]
    fun create_vault_for_testing(ctx: &mut TxContext): (Vault<A, VAULT>, Balance<VAULT>) {
        let (ya_treasury, meta) = create_a_treasury(ctx);

        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 1000,
            target_alloc_weight_bps: 4000,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_c, StrategyState {
            borrowed: 2000,
            target_alloc_weight_bps: 1000,
            max_borrow: option::some(1500),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);
        vector::push_back(&mut strategy_withdraw_priority_order, id_c);

        let vault = Vault<A, VAULT> {
            id: object::new(ctx),

            free_balance: mint_a_balance(1000),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 10000);

        sui::test_utils::destroy(meta);

        (vault, lp)
    }

    #[test]
    fun test_withdraw_from_free_balance() {
        let ctx = tx_context::dummy();
        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let (vault, lp) = create_vault_for_testing(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let to_withdraw = balance::split(&mut lp, 500);
        let ticket = withdraw(&mut vault, to_withdraw, &clock);

        let keys = vector::empty();
        vector::push_back(&mut keys, id_a);
        vector::push_back(&mut keys, id_b);
        vector::push_back(&mut keys, id_c);
        let values = vector::empty();
        vector::push_back(&mut values, 0);
        vector::push_back(&mut values, 0);
        vector::push_back(&mut values, 0);
        assert_ticket_values(
            &ticket, 500, keys, values, 500,
        );

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(ticket);
    }

    #[test]
    fun test_withdraw_over_cap() {
        let ctx = tx_context::dummy();
        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let (vault, lp) = create_vault_for_testing(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let to_withdraw = balance::split(&mut lp, 2200);
        let ticket = withdraw(&mut vault, to_withdraw, &clock);

        let keys = vector::empty();
        vector::push_back(&mut keys, id_a);
        vector::push_back(&mut keys, id_b);
        vector::push_back(&mut keys, id_c);
        let values = vector::empty();
        vector::push_back(&mut values, 0);
        vector::push_back(&mut values, 0);
        vector::push_back(&mut values, 200);
        assert_ticket_values(
            &ticket, 2000, keys, values, 2200,
        );

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(ticket);
    }

    #[test]
    fun test_withdraw_proportional_tiny() {
        let ctx = tx_context::dummy();
        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let (vault, lp) = create_vault_for_testing(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let to_withdraw = balance::split(&mut lp, 2501);
        let ticket = withdraw(&mut vault, to_withdraw, &clock);

        let keys = vector::empty();
        vector::push_back(&mut keys, id_a);
        vector::push_back(&mut keys, id_b);
        vector::push_back(&mut keys, id_c);
        let values = vector::empty();
        vector::push_back(&mut values, 1);
        vector::push_back(&mut values, 0);
        vector::push_back(&mut values, 500);
        assert_ticket_values(
            &ticket, 2000, keys, values, 2501,
        );

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(ticket);
    }

    #[test]
    fun test_withdraw_proportional_exact() {
        let ctx = tx_context::dummy();
        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let (vault, lp) = create_vault_for_testing(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let to_withdraw = balance::split(&mut lp, 3250);
        let ticket = withdraw(&mut vault, to_withdraw, &clock);

        let keys = vector::empty();
        vector::push_back(&mut keys, id_a);
        vector::push_back(&mut keys, id_b);
        vector::push_back(&mut keys, id_c);
        let values = vector::empty();
        vector::push_back(&mut values, 500);
        vector::push_back(&mut values, 100);
        vector::push_back(&mut values, 650);
        assert_ticket_values(
            &ticket, 2000, keys, values, 3250,
        );

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(ticket);
    }

    #[test]
    fun test_withdraw_proportional_undivisible() {
        let ctx = tx_context::dummy();
        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let (vault, lp) = create_vault_for_testing(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let to_withdraw = balance::split(&mut lp, 3251);
        let ticket = withdraw(&mut vault, to_withdraw, &clock);

        let keys = vector::empty();
        vector::push_back(&mut keys, id_a);
        vector::push_back(&mut keys, id_b);
        vector::push_back(&mut keys, id_c);
        let values = vector::empty();
        vector::push_back(&mut values, 501);
        vector::push_back(&mut values, 100);
        vector::push_back(&mut values, 650);
        assert_ticket_values(
            &ticket, 2000, keys, values, 3251,
        );

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(ticket);
    }

    #[test]
    fun test_withdraw_almost_all() {
        let ctx = tx_context::dummy();
        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let (vault, lp) = create_vault_for_testing(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let to_withdraw = balance::split(&mut lp, 9999);
        let ticket = withdraw(&mut vault, to_withdraw, &clock);

        let keys = vector::empty();
        vector::push_back(&mut keys, id_a);
        vector::push_back(&mut keys, id_b);
        vector::push_back(&mut keys, id_c);
        let values = vector::empty();
        vector::push_back(&mut values, 5000);
        vector::push_back(&mut values, 1000);
        vector::push_back(&mut values, 1999);
        assert_ticket_values(
            &ticket, 2000, keys, values, 9999,
        );

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(ticket);
    }

    #[test]
    fun test_withdraw_all() {
        let ctx = tx_context::dummy();
        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let (vault, lp) = create_vault_for_testing(&mut ctx);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let ticket = withdraw(&mut vault, lp, &clock);

        let keys = vector::empty();
        vector::push_back(&mut keys, id_a);
        vector::push_back(&mut keys, id_b);
        vector::push_back(&mut keys, id_c);
        let values = vector::empty();
        vector::push_back(&mut values, 5000);
        vector::push_back(&mut values, 1000);
        vector::push_back(&mut values, 2000);
        assert_ticket_values(
            &ticket, 2000, keys, values, 10000,
        );

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(ticket);
    }

    #[test]
    fun test_withdraw_ticket_redeem() {
        let ctx = tx_context::dummy();
        let id_a = object::id_from_address(@0xA);
        let id_b = object::id_from_address(@0xB);
        let id_c = object::id_from_address(@0xC);

        let (vault, lp) = create_vault_for_testing(&mut ctx);

        let strategy_infos = vec_map::empty();
        vec_map::insert(&mut strategy_infos, id_a, StrategyWithdrawInfo {
            to_withdraw: 2500,
            withdrawn_balance: balance::create_for_testing(2500),
            has_withdrawn: true,
        });
        vec_map::insert(&mut strategy_infos, id_b, StrategyWithdrawInfo {
            to_withdraw: 0,
            withdrawn_balance: balance::zero(),
            has_withdrawn: false,
        });
        vec_map::insert(&mut strategy_infos, id_c, StrategyWithdrawInfo {
            to_withdraw: 1000,
            withdrawn_balance: balance::create_for_testing(500),
            has_withdrawn: true,
        });
        let ticket =  WithdrawTicket {
            to_withdraw_from_free_balance: 1000,
            strategy_infos,
            lp_to_burn: balance::split(&mut lp, 4500),
        };

        let out = redeem_withdraw_ticket(&mut vault, ticket);

        assert!(balance::value(&out) == 4000, 0);

        let strat_state_a = vec_map::get(&vault.strategies, &id_a);
        assert!(strat_state_a.borrowed == 2500, 0);
        let strat_state_a = vec_map::get(&vault.strategies, &id_b);
        assert!(strat_state_a.borrowed == 1000, 0);
        let strat_state_a = vec_map::get(&vault.strategies, &id_c);
        assert!(strat_state_a.borrowed == 1000, 0);

        assert!(balance::value(&vault.free_balance) == 0, 0);
        assert!(coin::total_supply(&vault.lp_treasury) == 5500, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(out);
    }

    #[test]
    fun test_strategy_get_rebalance_amounts_one_strategy() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 10000,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(1000),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 10000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        
        // free_balance: 1000
        // released from profits: 1000
        // strategies:
        //   - borrowed: 5000/inf, weight: 100%
        // expect:
        //   - can_borrow: 2000, to_repay: 0

        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 2000, 0);
        assert!(to_repay == 0, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
    }

    #[test]
    fun test_strategy_get_rebalance_amounts_two_strategies_balanced() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(1000),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 12000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        
        // free_balance: 1000
        // released from profits: 1000
        // strategies:
        //   - borrowed: 5000/inf, weight: 50%
        //   - borrowed: 5000/inf, weight: 50%
        // expect:
        //   - can_borrow: 1000, to_repay: 0
        //   - can_borrow: 1000, to_repay: 0

        // a
        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 1000, 0);
        assert!(to_repay == 0, 0);
        // b
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_b);
        assert!(can_borrow == 1000, 0);
        assert!(to_repay == 0, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_b);
    }

    #[test]
    fun test_strategy_get_rebalance_amounts_two_strategies_one_balanced() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 6000,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(0),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 12000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        // free_balance: 0
        // released from profits: 1000
        // strategies:
        //   - borrowed: 5000/inf, weight: 50%
        //   - borrowed: 6000/inf, weight: 50%
        // expect:
        //   - can_borrow: 1000, to_repay: 0
        //   - can_borrow: 0, to_repay: 0

        // a
        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 1000, 0);
        assert!(to_repay == 0, 0);
        // b
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_b);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 0, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_b);
    }

    #[test]
    fun test_strategy_get_rebalance_amounts_two_strategies_both_unbalanced() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 4000,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 5000,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(50),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 9100);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 50 * 1000);

        
        // free_balance: 50
        // released from profits: 50
        // strategies:
        //   - borrowed: 4000/inf, weight: 50%
        //   - borrowed: 5000/inf, weight: 50%
        // expect:
        //   - can_borrow: 550, to_repay: 0
        //   - can_borrow: 0, to_repay: 450

        // a
        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 550, 0);
        assert!(to_repay == 0, 0);
        // b
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_b);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 450, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_b);
    }
 
    #[test]
    fun test_strategy_get_rebalance_amounts_with_cap_balanced() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_c = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);
        let id_c = object::uid_to_inner(&vault_access_c.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 2000,
            target_alloc_weight_bps: 2000,
            max_borrow: option::some(2000),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 4000,
            target_alloc_weight_bps: 4000,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_c, StrategyState {
            borrowed: 4000,
            target_alloc_weight_bps: 4000,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);
        vector::push_back(&mut strategy_withdraw_priority_order, id_c);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(0),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 10000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 0 * 1000);

        
        // free_balance: 0
        // released from profits: 0
        // strategies:
        //   - borrowed: 2000/2000, weight: 20%
        //   - borrowed: 4000/inf, weight: 40%
        //   - borrowed: 4000/inf, weight: 40%
        // expect:
        //   - can_borrow: 0, to_repay: 0
        //   - can_borrow: 0, to_repay: 0
        //   - can_borrow: 0, to_repay: 0

        // a
        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 0, 0);
        // b
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_b);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 0, 0);
        // c
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_c);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 0, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_b);
        sui::test_utils::destroy(vault_access_c);
    }

    #[test]
    fun test_strategy_get_rebalance_amounts_with_cap_over_cap() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_c = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);
        let id_c = object::uid_to_inner(&vault_access_c.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 1000,
            target_alloc_weight_bps: 20_00,
            max_borrow: option::some(500),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 4000,
            target_alloc_weight_bps: 40_00,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_c, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 40_00,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);
        vector::push_back(&mut strategy_withdraw_priority_order, id_c);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(2500),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 15000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 2500 * 1000);

        
        // free_balance: 2500
        // released from profits: 2500
        // strategies:
        //   - borrowed: 1000/500, weight: 20%
        //   - borrowed: 4000/inf, weight: 40%
        //   - borrowed: 5000/inf, weight: 40%
        // expect:
        //   - can_borrow: 0, to_repay: 500
        //   - can_borrow: 3250, to_repay: 0
        //   - can_borrow: 2250, to_repay: 0

        // a
        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 500, 0);
        // b
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_b);
        assert!(can_borrow == 3250, 0);
        assert!(to_repay == 0, 0);
        // c
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_c);
        assert!(can_borrow == 2250, 0);
        assert!(to_repay == 0, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_b);
        sui::test_utils::destroy(vault_access_c);
    }

    #[test]
    fun test_strategy_get_rebalance_amounts_with_cap_over_and_under_cap() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_c = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_d = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);
        let id_c = object::uid_to_inner(&vault_access_c.id);
        let id_d = object::uid_to_inner(&vault_access_d.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 1000,
            target_alloc_weight_bps: 10_00,
            max_borrow: option::some(500),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 4000,
            target_alloc_weight_bps: 30_00,
            max_borrow: option::some(5000),
        });
        vec_map::insert(&mut strategies, id_c, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 30_00,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_d, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 30_00,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);
        vector::push_back(&mut strategy_withdraw_priority_order, id_c);
        vector::push_back(&mut strategy_withdraw_priority_order, id_d);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(2500),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 20000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 2500 * 1000);

        
        // free_balance: 2500
        // released from profits: 2500
        // strategies:
        //   - borrowed: 1000/500, weight: 10%
        //   - borrowed: 4000/5000, weight: 30%
        //   - borrowed: 5000/inf, weight: 30%
        //   - borrowed: 5000/inf, weight: 30%
        // expect:
        //   - can_borrow: 0, to_repay: 500
        //   - can_borrow: 1000, to_repay: 0
        //   - can_borrow: 2250, to_repay: 0
        //   - can_borrow: 2250, to_repay: 0

        // a
        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 500, 0);
        // b
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_b);
        assert!(can_borrow == 1000, 0);
        assert!(to_repay == 0, 0);
        // c
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_c);
        assert!(can_borrow == 2250, 0);
        assert!(to_repay == 0, 0);
        // d
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_d);
        assert!(can_borrow == 2250, 0);
        assert!(to_repay == 0, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_b);
        sui::test_utils::destroy(vault_access_c);
        sui::test_utils::destroy(vault_access_d);
    }

    #[test]
    fun test_strategy_get_rebalance_amounts_with_cap_over_and_two_under_cap() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_c = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_d = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_e = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);
        let id_c = object::uid_to_inner(&vault_access_c.id);
        let id_d = object::uid_to_inner(&vault_access_d.id);
        let id_e = object::uid_to_inner(&vault_access_e.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 1000,
            target_alloc_weight_bps: 20_00,
            max_borrow: option::some(500),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 4000,
            target_alloc_weight_bps: 20_00,
            max_borrow: option::some(5000),
        });
        vec_map::insert(&mut strategies, id_c, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 20_00,
            max_borrow: option::some(10000),
        });
        vec_map::insert(&mut strategies, id_d, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 20_00,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_e, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 20_00,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);
        vector::push_back(&mut strategy_withdraw_priority_order, id_c);
        vector::push_back(&mut strategy_withdraw_priority_order, id_d);
        vector::push_back(&mut strategy_withdraw_priority_order, id_e);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(2500),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 25000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 2500 * 1000);

        
        // free_balance: 2500
        // released from profits: 2500
        // strategies:
        //   - borrowed: 1000/500, weight: 10%
        //   - borrowed: 4000/5000, weight: 20%
        //   - borrowed: 5000/10000, weight: 20%
        //   - borrowed: 5000/inf, weight: 20%
        //   - borrowed: 5000/inf, weight: 20%
        // expect:
        //   - can_borrow: 0, to_repay: 500
        //   - can_borrow: 1000, to_repay: 0
        //   - can_borrow: 1500, to_repay: 0
        //   - can_borrow: 1500, to_repay: 0
        //   - can_borrow: 1500, to_repay: 0

        // a
        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 500, 0);
        // b
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_b);
        assert!(can_borrow == 1000, 0);
        assert!(to_repay == 0, 0);
        // c
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_c);
        assert!(can_borrow == 1500, 0);
        assert!(to_repay == 0, 0);
        // d
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_d);
        assert!(can_borrow == 1500, 0);
        assert!(to_repay == 0, 0);
        // e
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_e);
        assert!(can_borrow == 1500, 0);
        assert!(to_repay == 0, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_b);
        sui::test_utils::destroy(vault_access_c);
        sui::test_utils::destroy(vault_access_d);
        sui::test_utils::destroy(vault_access_e);
    }

    #[test]
    fun test_strategy_get_rebalance_amounts_with_cap_over_reduce_and_two_under_cap() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_c = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_d = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_e = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);
        let id_c = object::uid_to_inner(&vault_access_c.id);
        let id_d = object::uid_to_inner(&vault_access_d.id);
        let id_e = object::uid_to_inner(&vault_access_e.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 6000,
            target_alloc_weight_bps: 4_00,
            max_borrow: option::some(5000),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 4000,
            target_alloc_weight_bps: 24_00,
            max_borrow: option::some(5000),
        });
        vec_map::insert(&mut strategies, id_c, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 22_00,
            max_borrow: option::some(10000),
        });
        vec_map::insert(&mut strategies, id_d, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 30_00,
            max_borrow: option::none(),
        });
        vec_map::insert(&mut strategies, id_e, StrategyState {
            borrowed: 10000,
            target_alloc_weight_bps: 20_00,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);
        vector::push_back(&mut strategy_withdraw_priority_order, id_c);
        vector::push_back(&mut strategy_withdraw_priority_order, id_d);
        vector::push_back(&mut strategy_withdraw_priority_order, id_e);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(2500),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 35000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 2500 * 1000);

        
        // free_balance: 2500
        // released from profits: 2500
        // strategies:
        //   - borrowed: 6000/5000, weight: 4%
        //   - borrowed: 4000/5000, weight: 24%
        //   - borrowed: 5000/10000, weight: 22%
        //   - borrowed: 5000/inf, weight: 30%
        //   - borrowed: 5000/inf, weight: 20%
        // expect:
        //   - can_borrow: 0, to_repay: 4600
        //   - can_borrow: 1000, to_repay: 0
        //   - can_borrow: 3738, to_repay: 0
        //   - can_borrow: 6916, to_repay: 0
        //   - can_borrow: 0, to_repay: 2056

        // a
        let amts = calc_rebalance_amounts(&vault, &clock);
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_a);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 4422, 0);
        // b
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_b);
        assert!(can_borrow == 1000, 0);
        assert!(to_repay == 0, 0);
        // c
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_c);
        assert!(can_borrow == 3684, 0);
        assert!(to_repay == 0, 0);
        // d
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_d);
        assert!(can_borrow == 6842, 0);
        assert!(to_repay == 0, 0);
        // e
        let (can_borrow, to_repay) = rebalance_amounts_get(&amts, &vault_access_e);
        assert!(can_borrow == 0, 0);
        assert!(to_repay == 2106, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_b);
        sui::test_utils::destroy(vault_access_c);
        sui::test_utils::destroy(vault_access_d);
        sui::test_utils::destroy(vault_access_e);
    }

    #[test]
    fun test_strategy_hand_over_profit() {
        let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 1000,
            target_alloc_weight_bps: 10000,
            max_borrow: option::none(),
        });

        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(1000),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 10_00,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 3000);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let profit = balance::create_for_testing<A>(5000);
        strategy_hand_over_profit(
            &mut vault, &vault_access_a, profit, &clock
        );

        assert!(balance::value(&vault.free_balance) == 2000, 0);
        assert!(tlb::remaining_unlock(&vault.time_locked_profit, &clock) == 13998, 0);
        assert!(tlb::extraneous_locked_amount(&vault.time_locked_profit) == 2, 0);
        assert!(tlb::unlock_start_ts_sec(&vault.time_locked_profit) == timestamp_sec(&clock), 0);
        assert!(tlb::unlock_per_second(&vault.time_locked_profit) == 3, 0);
        assert!(tlb::final_unlock_ts_sec(&vault.time_locked_profit) == timestamp_sec(&clock) + 4666, 0);
        assert!(balance::value(&vault.performance_fee_balance) == 600, 0);

        let fee_yt = balance::create_for_testing<VAULT>(600);
        let ticket = withdraw(&mut vault, fee_yt, &clock);
        let fee_t = redeem_withdraw_ticket(&mut vault, ticket);
        assert!(balance::value(&fee_t) == 500, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(clock);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(fee_t);
    }

    #[test]
    fun test_remove_strategy() {
                let ctx = tx_context::dummy();
        let (ya_treasury, meta) = create_a_treasury(&mut ctx);

        let vault_access_a = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_b = VaultAccess { id: object::new(&mut ctx) };
        let vault_access_c = VaultAccess { id: object::new(&mut ctx) };
        let id_a = object::uid_to_inner(&vault_access_a.id);
        let id_b = object::uid_to_inner(&vault_access_b.id);
        let id_c = object::uid_to_inner(&vault_access_c.id);

        let strategies = vec_map::empty();
        vec_map::insert(&mut strategies, id_a, StrategyState {
            borrowed: 6000,
            target_alloc_weight_bps: 4_00,
            max_borrow: option::some(5000),
        });
        vec_map::insert(&mut strategies, id_b, StrategyState {
            borrowed: 1000,
            target_alloc_weight_bps: 50_00,
            max_borrow: option::some(5000),
        });
        vec_map::insert(&mut strategies, id_c, StrategyState {
            borrowed: 5000,
            target_alloc_weight_bps: 46_00,
            max_borrow: option::some(10000),
        });


        let strategy_withdraw_priority_order = vector::empty();
        vector::push_back(&mut strategy_withdraw_priority_order, id_a);
        vector::push_back(&mut strategy_withdraw_priority_order, id_b);
        vector::push_back(&mut strategy_withdraw_priority_order, id_c);

        let vault = Vault<A, VAULT> {
            id: object::new(&mut ctx),

            free_balance: mint_a_balance(2500),
            time_locked_profit: tlb::create(mint_a_balance(10000), 0, 1),
            lp_treasury: ya_treasury, 
            strategies,
            performance_fee_balance: balance::zero(),
            strategy_withdraw_priority_order,
            withdraw_ticket_issued: false,

            tvl_cap: option::none(),
            profit_unlock_duration_sec: DEFAULT_PROFIT_UNLOCK_DURATION_SEC,
            performance_fee_bps: 0,

            version: MODULE_VERSION,
        };
        let lp = coin::mint_balance(&mut vault.lp_treasury, 15500);

        sui::test_utils::destroy(meta);

        let clock = clock::create_for_testing(&mut ctx);
        clock::increment_for_testing(&mut clock, 1000 * 1000);

        let admin_cap = AdminCap<VAULT>{ id: object::new(&mut ctx) };
        let ticket = new_strategy_removal_ticket(vault_access_b, mint_a_balance(10000));
        let ids_for_weights = vector::empty();
        vector::push_back(&mut ids_for_weights, id_a);
        vector::push_back(&mut ids_for_weights, id_c);
        let new_weights = vector::empty();
        vector::push_back(&mut new_weights, 30_00);
        vector::push_back(&mut new_weights, 70_00);
        remove_strategy(&admin_cap, &mut vault, ticket, ids_for_weights, new_weights, &clock);

        assert!(vec_map::size(&vault.strategies) == 2, 0);
        assert!(vec_map::get(&vault.strategies, &id_a).target_alloc_weight_bps == 30_00, 0);
        assert!(vec_map::get(&vault.strategies, &id_c).target_alloc_weight_bps == 70_00, 0);
        let exp_priority_order = vector::empty();
        vector::push_back(&mut exp_priority_order, id_a);
        vector::push_back(&mut exp_priority_order, id_c);
        assert!(vault.strategy_withdraw_priority_order == exp_priority_order, 0);

        sui::test_utils::destroy(vault);
        sui::test_utils::destroy(lp);
        sui::test_utils::destroy(admin_cap);
        sui::test_utils::destroy(vault_access_a);
        sui::test_utils::destroy(vault_access_c);
        sui::test_utils::destroy(clock);
    }
}