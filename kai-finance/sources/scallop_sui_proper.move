module kai::scallop_sui_proper {
    use std::option::{Self, Option};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::Clock;
    use sui::math;
    use sui::coin;
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;

    use scallop_protocol::reserve::MarketCoin;
    use scallop_protocol::version::Version as ScallopVersion;
    use scallop_protocol::market::Market as ScallopMarket;
    use scallop_pool::spool_account::SpoolAccount as ScallopPoolAccount;
    use scallop_pool::spool::Spool as ScallopPool;
    use scallop_pool::rewards_pool::RewardsPool as ScallopRewardsPool;

    use kai_ywhusdte_ysui::ysui::YSUI;

    use kai::vault::{
        Self, Vault, VaultAccess, AdminCap as VaultAdminCap, RebalanceAmounts, WithdrawTicket,
        StrategyRemovalTicket
    };
    use kai::util::muldiv;

    /* ================= constants ================= */

    const MODULE_VERSION: u64 = 1; 

    const SCALLOP_POOL_ID: address = @0x4f0ba970d3c11db05c8f40c64a15b6a33322db3702d634ced6536960ab6f3ee4;
    const SCALLOP_MARKET_ID: address = @0xa757975255146dc9686aa823b7838b507f315d704f428cbadad2f4ea061939d9;
    const SCALLOP_REWARDS_POOL_ID: address = @0x162250ef72393a4ad3d46294c4e1bdfcb03f04c869d390e7efbfc995353a7ee9;

    /* ================= errors ================= */

    /// Invalid `AdminCap` has been provided for the strategy
    const EInvalidAdmin: u64 = 0;

    /// Invalid Scallop pool ID provided
    const EInvalidScallopPool: u64 = 1;

    /// Invalid Scallop market ID provided
    const EInvalidScallopMarket: u64 = 2;

    /// The strategy cannot be removed from vault if it has pending rewards
    const EHasPendingRewards: u64 = 3;

    /// Calling functions from the wrong package version
    const EWrongVersion: u64 =  4;

    /// Migration is not an upgrade
    const ENotUpgrade: u64 = 5;

    /* ================= AdminCap ================= */

    struct AdminCap has key, store {
        id: UID,
    }

    /* ================= Strategy ================= */

    struct Strategy has key {
        id: UID,
        admin_cap_id: ID,
        vault_access: Option<VaultAccess>,
        scallop_pool_acc: ScallopPoolAccount<MarketCoin<SUI>>,
        underlying_nominal_value_sui: u64,
        collected_profit_sui: Balance<SUI>,
        version: u64,
    }

    fun assert_scallop_pool(pool: &ScallopPool) {
        assert!(object::id_address(pool) == SCALLOP_POOL_ID, EInvalidScallopPool);
    }

    #[lint_allow(self_transfer)]
    entry public(friend) fun new(
        scallop_pool: &mut ScallopPool, clock: &Clock, ctx: &mut TxContext
    ) {
        assert_scallop_pool(scallop_pool);

        let admin_cap = AdminCap { id: object::new(ctx) };
        let admin_cap_id = object::id(&admin_cap);

        let scallop_pool_acc = scallop_pool::user::new_spool_account(scallop_pool, clock, ctx);

        let strategy = Strategy {
            id: object::new(ctx),
            admin_cap_id,
            vault_access: option::none(),
            scallop_pool_acc,
            underlying_nominal_value_sui: 0,
            collected_profit_sui: balance::zero(),
            version: MODULE_VERSION,
        };
        transfer::share_object(strategy);

        transfer::transfer(
            admin_cap, tx_context::sender(ctx)
        );

    }

    fun assert_version(strategy: &Strategy) {
        assert!(strategy.version == MODULE_VERSION, EWrongVersion);
    }

    /* ================= admin ================= */

    fun assert_admin(cap: &AdminCap, strategy: &Strategy) {
        let admin_cap_id = object::id(cap);
        assert!(admin_cap_id == strategy.admin_cap_id, EInvalidAdmin);
    }

    entry fun join_vault(
        vault_cap: &VaultAdminCap<YSUI>, vault: &mut Vault<SUI, YSUI>,
        strategy_cap: &AdminCap, strategy: &mut Strategy,
        ctx: &mut TxContext
    ) {
        assert_version(strategy);
        assert_admin(strategy_cap, strategy);

        let access = vault::add_strategy(vault_cap, vault, ctx);
        option::fill(&mut strategy.vault_access, access); // aborts if `is_some`
    }
 
    fun assert_scallop_market(market: &ScallopMarket) {
        assert!(object::id_address(market) == SCALLOP_MARKET_ID, EInvalidScallopMarket);
    }

    fun assert_scallop_rewards_pool(pool: &ScallopRewardsPool<SUI>) {
        assert!(object::id_address(pool) == SCALLOP_REWARDS_POOL_ID, EInvalidScallopMarket);
    }

    public fun remove_from_vault(
        cap: &AdminCap, strategy: &mut Strategy,
        scallop_version: &ScallopVersion, scallop_market: &mut ScallopMarket, scallop_pool: &mut ScallopPool,
        scallop_rewards_pool: &mut ScallopRewardsPool<SUI>,
        clock: &Clock, ctx: &mut TxContext
    ): StrategyRemovalTicket<SUI, YSUI> {
        assert_admin(cap, strategy);
        assert_version(strategy);
        assert_scallop_market(scallop_market);
        assert_scallop_pool(scallop_pool);
        assert_scallop_rewards_pool(scallop_rewards_pool);

        let rewards = scallop_pool::user::redeem_rewards(
            scallop_pool, scallop_rewards_pool, &mut strategy.scallop_pool_acc, clock, ctx
        );
        assert!(coin::value(&rewards) == 0, EHasPendingRewards);
        assert!(balance::value(&strategy.collected_profit_sui) == 0, EHasPendingRewards);
        coin::destroy_zero(rewards);


        let amount_ssui = scallop_pool::spool_account::stake_amount(&strategy.scallop_pool_acc);
        let unstaked_ssui = scallop_pool::user::unstake(
            scallop_pool, &mut strategy.scallop_pool_acc, amount_ssui, clock, ctx
        );
        let redeemed_coin = scallop_protocol::redeem::redeem(
            scallop_version, scallop_market, unstaked_ssui, clock, ctx
        );
        let returned_balance = coin::into_balance(redeemed_coin);

        strategy.underlying_nominal_value_sui = 0;

        vault::new_strategy_removal_ticket(
            option::extract(&mut strategy.vault_access), returned_balance
        )
    }

    entry fun migrate(
        cap: &AdminCap,  strategy: &mut Strategy
    ) {
        assert_admin(cap, strategy);
        assert!(strategy.version < MODULE_VERSION, ENotUpgrade);
        strategy.version = MODULE_VERSION;
    }

    /* ================= strategy operations ================= */

    public fun rebalance(
        cap: &AdminCap, strategy: &mut Strategy, vault: &mut Vault<SUI, YSUI>,
        amounts: &RebalanceAmounts,
        scallop_version: &ScallopVersion, scallop_market: &mut ScallopMarket, scallop_pool: &mut ScallopPool,
        clock: &Clock, ctx: &mut TxContext
    ) {
        assert_admin(cap, strategy);
        assert_version(strategy);
        assert_scallop_market(scallop_market);
        assert_scallop_pool(scallop_pool);

        let vault_access = option::borrow(&strategy.vault_access);
        let (can_borrow, to_repay) = vault::rebalance_amounts_get(amounts, vault_access);
        if (to_repay > 0) {
            let staked_amount_ssui = scallop_pool::spool_account::stake_amount(&strategy.scallop_pool_acc);
            let unstake_ssui_amt = muldiv(
                staked_amount_ssui,
                to_repay,
                strategy.underlying_nominal_value_sui,
            );

            let unstaked_ssui = scallop_pool::user::unstake(
                scallop_pool, &mut strategy.scallop_pool_acc, unstake_ssui_amt, clock, ctx
            );
            let redeemed_coin = scallop_protocol::redeem::redeem(
                scallop_version, scallop_market, unstaked_ssui, clock, ctx
            );
            let redeemed_balance_sui = coin::into_balance(redeemed_coin);

            if (balance::value(&redeemed_balance_sui) > to_repay) {
                let extra_amt = balance::value(&redeemed_balance_sui) - to_repay;
                balance::join(
                    &mut strategy.collected_profit_sui,
                    balance::split(&mut redeemed_balance_sui, extra_amt)
                );
            };

            let repaid = balance::value(&redeemed_balance_sui);
            vault::strategy_repay(vault, vault_access, redeemed_balance_sui);

            strategy.underlying_nominal_value_sui = strategy.underlying_nominal_value_sui - repaid;
        } else if (can_borrow > 0) {
            let borrow_amt = math::min(can_borrow, vault::free_balance(vault));
            let borrowed = coin::from_balance(
                vault::strategy_borrow(vault, vault_access, borrow_amt), ctx
            );

            let ssui = scallop_protocol::mint::mint(
                scallop_version, scallop_market, borrowed, clock, ctx
            );
            scallop_pool::user::stake(
                scallop_pool, &mut strategy.scallop_pool_acc, ssui, clock, ctx
            );

            strategy.underlying_nominal_value_sui = strategy.underlying_nominal_value_sui + borrow_amt;
        }
    }

    /// Collect the profits and hand them over to the vault.
    public fun collect_and_hand_over_profit(
        cap: &AdminCap, strategy: &mut Strategy, vault: &mut Vault<SUI, YSUI>,
        scallop_pool: &mut ScallopPool, scallop_rewards_pool: &mut ScallopRewardsPool<SUI>,
        clock: &Clock, ctx: &mut TxContext
    ) {
        assert_admin(cap, strategy);
        assert_version(strategy);
        assert_scallop_pool(scallop_pool);
        assert_scallop_rewards_pool(scallop_rewards_pool);

        let vault_access = option::borrow(&strategy.vault_access);

        let coin = scallop_pool::user::redeem_rewards(
            scallop_pool, scallop_rewards_pool, &mut strategy.scallop_pool_acc, clock, ctx
        );
        balance::join(&mut strategy.collected_profit_sui, coin::into_balance(coin));

        let profit = balance::withdraw_all(&mut strategy.collected_profit_sui);

        vault::strategy_hand_over_profit(vault, vault_access, profit, clock);
    }

    /* ================= user operations ================= */

    public fun withdraw(
        strategy: &mut Strategy, ticket: &mut WithdrawTicket<SUI, YSUI>,
        scallop_version: &ScallopVersion, scallop_market: &mut ScallopMarket, scallop_pool: &mut ScallopPool,
        clock: &Clock, ctx: &mut TxContext
    ) {
        assert_version(strategy);
        assert_scallop_market(scallop_market);
        assert_scallop_pool(scallop_pool);

        let vault_access = option::borrow(&strategy.vault_access);
        let to_withdraw = vault::withdraw_ticket_to_withdraw(ticket, vault_access);
        if (to_withdraw == 0) {
            return
        };

        let staked_amount_ssui = scallop_pool::spool_account::stake_amount(&strategy.scallop_pool_acc);
        let unstake_ssui_amt = muldiv(
            staked_amount_ssui,
            to_withdraw,
            strategy.underlying_nominal_value_sui,
        );

        let unstaked_ssui = scallop_pool::user::unstake(
            scallop_pool, &mut strategy.scallop_pool_acc, unstake_ssui_amt, clock, ctx
        );
        let redeemed_coin = scallop_protocol::redeem::redeem(
            scallop_version, scallop_market, unstaked_ssui, clock, ctx
        );
        let redeemed_balance_sui = coin::into_balance(redeemed_coin);

        if (balance::value(&redeemed_balance_sui) > to_withdraw) {
            let profit_amt = balance::value(&redeemed_balance_sui) - to_withdraw;
            balance::join(
                &mut strategy.collected_profit_sui, 
                balance::split(&mut redeemed_balance_sui, profit_amt),
            );
        };

        vault::strategy_withdraw_to_ticket(ticket, vault_access, redeemed_balance_sui);

        // `to_withdraw` amount is used intentionally here instead of the actual amount which
        // can be lower in some cases (see comments in `vault::redeem_withdraw_ticket`) 
        strategy.underlying_nominal_value_sui = strategy.underlying_nominal_value_sui - to_withdraw;
    }
}
