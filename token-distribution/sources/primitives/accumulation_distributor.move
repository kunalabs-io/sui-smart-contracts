/// `AccumulationDistributor` is a component that distributes balances to multiple participants
/// proportionally based on the number number of "shares" they have staked in the distributor.
/// Unlike the `TimeDistributor` the emissions are not based on the passage of time but rather
/// on discrete (manual) deposits using the `top_up` function.
/// 
/// For example, if there are two positions with 100 and 300 shares each, and if a balance
/// of 100 of coin type `T` is then deposited (via the `top_up` function) into the distributor,
/// the stake holders will recieve 25 and 75 of the deposited balance respectively.
/// 
/// This distributor can handle distribution of multiple different coin types simultaniously
/// (notice that the `AccumulationDistributor` struct has no type parameters). This works transparently
/// by simply depositing any coin type at any time using the `top_up` function. The heterogeneous coin
/// balances are stored internally using `sui::bag`.
///
/// This module doesn't implement any permission functionality and it's intended to be used as a
/// building block for other modules.  
/// 
/// Usage:
/// ```
/// let ad = ad::create(&mut ctx);
/// let position = ad::deposit_shares_new(&mut ad, 100);
/// 
/// let balance: Balance<FOO> = <...>;
/// ad::top_up(&mut ad, balance);
/// 
/// let balance = ad::withdraw_all_rewards<FOO>(&mut ad, &mut position);
/// ```

module token_distribution::accumulation_distributor {
    use std::type_name::{Self, TypeName};
    use std::option;
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};
    use sui::bag::{Self, Bag};
    use sui::vec_map::{Self, VecMap};

    /* ================= errors ================= */

    /// The position doesn't belong to the provided distributor.
    const EInvalidPosition: u64 = 0;
    /// Withdraw amount too large.
    const ENotEnough: u64 = 1;
    /// The position still contains shares or balances and cannot be destroyed.
    const ENotEmpty: u64 = 2;

    /* ================= constants ================= */

    // Multiplier used to increase precision. 2^64.
    const Q64: u128 = 0x10000000000000000;

    /* ================= AccumulationDistributor ================= */

    struct AccumulationDistributor has store {
        id: UID,
        // `Bag` that holds balances to be claimed by stake holders.
        balances: Bag,
        // Aaccumulated rewards per share for each coin type in the distributor. The balance
        // amount each share holder will get is calculated based on this number and the number of shares
        // they hold. This number is multiplied with the Q64 constant to increase precision.
        acc_rewards_per_share_x64: VecMap<TypeName, u256>,
        // Total amount of shares in the distributor. Sum of all shares in all positions.
        total_shares: u64,

        // `Bag` that holds extraneous balances. `top_up` balances will go here when `total_shares` is 0.
        extraneous_balances: Bag,
    }

    /// Return the total number of shares in the distributor. Sum of all shares in all position.
    public fun total_shares(self: &AccumulationDistributor): u64 {
        self.total_shares
    }

    /// Check whether the distributor holds the specified currency based on its type name
    /// (e.g. `type_name::get<SUI>()`).
    public fun has_balance(self: &AccumulationDistributor, currency: &TypeName): bool {
        vec_map::contains(&self.acc_rewards_per_share_x64, currency)
    }

    /// Check whether the distributor holds currency of type `T`.
    public fun has_balance_with_type<T>(self: &AccumulationDistributor): bool {
        let type = type_name::get<T>();
        has_balance(self, &type)
    }

    /// Returns balance 
    public fun balance_value<T>(self: &AccumulationDistributor): u64 {
        let type = type_name::get<T>();
        let balance: &Balance<T> = bag::borrow(&self.balances, type);
        balance::value(balance)
    }

    /// Withdraws extraneous balance of currency of type `T`.
    public fun remove_extraneous_balance<T>(self: &mut AccumulationDistributor): Balance<T> {
        let type = type_name::get<T>();
        bag::remove(&mut self.extraneous_balances, type)
    }

    /* ================= Position ================= */

    /// Internal struct used for balance accounting of currencies handled by the distributor for a `Position`.
    struct PositionBalance has store {
        available_rewards: u64,
        last_acc_rewards_per_share_x64: u256
    }

    /// `Position` represents a stake in the distributor and its owner can collect any balances
    /// accumulated for the amount of shares that are held within it.
    struct Position has store {
        ad_id: ID,
        shares: u64,
        balances: VecMap<TypeName, PositionBalance>
    }

    /// Return the number of shares held within a `Position`.
    public fun position_shares(position: &Position): u64 {
        position.shares
    }

    /// Return the reward amount that can be withdrawn directly from the `Position`
    /// without needing to update its state. It is the max amount that can be used in the `withdraw_rewards_direct`
    /// call for this `Position`.
    public fun position_reward_value_direct(
        self: &AccumulationDistributor, position: &Position, type: TypeName
    ): u64 {
        let idx = vec_map::get_idx(&self.acc_rewards_per_share_x64, &type);
        let available_rewards = if (idx < vec_map::size(&position.balances)) {
            let (_, balance) = vec_map::get_entry_by_idx(&position.balances, idx);
            balance.available_rewards
        } else {
            0
        };

        available_rewards
    }

    /// Return the rewards amount that can be withdrawn directly from the `Position` without needing to
    /// update its state. It is the max amount that can be used in the `withdraw_rewards_direct`
    /// call for this `Position`.
    public fun position_rewards_value_direct_with_type<T>(
        self: &AccumulationDistributor, position: &Position
    ): u64 {
        let type = type_name::get<T>();
        position_reward_value_direct(self, position, type)
    }

    /// Return the total rewards (of the specified currency) rewarded to the `Position`.
    public fun position_rewards_value(
        self: &AccumulationDistributor, position: &Position, type: TypeName
    ): u64 {
        let idx = vec_map::get_idx(&self.acc_rewards_per_share_x64, &type);
        let available_rewards = if (idx < vec_map::size(&position.balances)) {
            let (_, balance) = vec_map::get_entry_by_idx(&position.balances, idx);
            balance.available_rewards
        } else {
            0
        };
        
        available_rewards + calc_position_unlockable_rewards_idx(self, position, idx)
    }

    /// Return the total rewards (of the specified currency `T`) rewarded to the `Position`.
    public fun position_rewards_value_with_type<T>(
        self: &AccumulationDistributor, position: &Position
    ): u64 {
        let type = type_name::get<T>();
        position_rewards_value(self, position, type)
    }

    /* ================= main ================= */

    /// Create a new `AccumulationDistributor`.
    public fun create(ctx: &mut TxContext): AccumulationDistributor {
        AccumulationDistributor {
            id: object::new(ctx),
            balances: bag::new(ctx),
            acc_rewards_per_share_x64: vec_map::empty(),
            total_shares: 0,

            extraneous_balances: bag::new(ctx),
        }
    }

    /// Top up the distributor with `Balance<T>`. This balance will get distributed to share holders
    /// if there are any or otherwise get deposited into `extraneous_balances` bag.
    public fun top_up<T>(self: &mut AccumulationDistributor, balance: Balance<T>) {
        // when there are no shares in the distributor the balance goes into the extraneous_balances bag.
        if (self.total_shares == 0) {
            let type = type_name::get<T>();

            if (bag::contains_with_type<TypeName, Balance<T>>(&self.extraneous_balances, type)) {
                let extraneous_balance: &mut Balance<T> = bag::borrow_mut(&mut self.extraneous_balances, type);
                balance::join(extraneous_balance, balance);
            } else {
                bag::add(&mut self.extraneous_balances, type, balance);
            };

            return
        };

        // add new balance if needed
        let type = type_name::get<T>();
        let idx_opt = vec_map::get_idx_opt(&self.acc_rewards_per_share_x64, &type);
        let idx = if (option::is_some(&idx_opt)) {
            option::destroy_some(idx_opt)
        } else {
            bag::add(
                &mut self.balances,
                type,
                balance::zero<T>(),
            );
            vec_map::insert(&mut self.acc_rewards_per_share_x64, type, 0);

            vec_map::size(&self.acc_rewards_per_share_x64) - 1
        };

        let self_balance = bag::borrow_mut<TypeName, Balance<T>>(&mut self.balances, type);
        let (_, acc_rewards_per_share_x64) = vec_map::get_entry_by_idx_mut(
            &mut self.acc_rewards_per_share_x64, idx
        );

        // Won't overflow because at most `2^64 - 1` of balance can be deposited at once and because of that
        // (when total_shares is 1) `acc_rewards_per_share_x64` can at most increase by 2^(128 - 1) per 
        // each `top_up` call. Therefore, it would take more than 2^128 calls for this to overflow and
        // if you do one call of max balance per second, it would take roughly 10^31 years to max this out.
        *acc_rewards_per_share_x64 = *acc_rewards_per_share_x64 + (
            (balance::value(&balance) as u256) * (Q64 as u256) / (self.total_shares as u256)
        );
        balance::join(self_balance, balance);
    }

    /// Deposit shares into the distributor and create a new `Position`.
    public fun deposit_shares_new(
        self: &mut AccumulationDistributor, amount: u64
    ): Position {
        let balances = vec_map::empty<TypeName, PositionBalance>();

        let i = 0;
        let n = vec_map::size(&self.acc_rewards_per_share_x64);
        while (i < n) {
            let (type, acc_rewards_per_share_x64) = vec_map::get_entry_by_idx(
                &self.acc_rewards_per_share_x64, i
            );

            vec_map::insert(&mut balances, *type, PositionBalance {
                available_rewards: 0,
                last_acc_rewards_per_share_x64: *acc_rewards_per_share_x64
            });

            i = i + 1;
        };

        self.total_shares = self.total_shares + amount;

        Position {
            ad_id: object::uid_to_inner(&self.id),
            shares: amount,
            balances,
        }
    }

    /// ** Do not call before asserting `position.ad_id` matches `self.id`! **
    /// Append `position.balances` with new currency types that have been added to the distributor interim.
    fun position_add_missing_balances(self: &AccumulationDistributor, position: &mut Position) {
        let start = vec_map::size(&position.balances);
        let end = vec_map::size(&self.acc_rewards_per_share_x64);

        let i = start;
        while (i < end) {
            let (type, _) = vec_map::get_entry_by_idx(&self.acc_rewards_per_share_x64, i);
            vec_map::insert(
                &mut position.balances,
                *type,
                PositionBalance {
                    available_rewards: 0,
                    last_acc_rewards_per_share_x64: 0
                }
            );

            i = i + 1
        }
    }

    /// Calculate the amount of new rewards rewardable to the position based on previous and current
    /// `acc_rewards_per_share`. `O(1)`.
    fun calc_position_unlockable_rewards_idx(
        self: &AccumulationDistributor, position: &Position, idx: u64
    ): u64 {
        let (_, to_acc_rewards_per_share_x64) = vec_map::get_entry_by_idx(
            &self.acc_rewards_per_share_x64, idx
        );
        let from_acc_rewards_per_share_x64 = if (idx < vec_map::size(&position.balances)) {
            let (_, balance) = vec_map::get_entry_by_idx(&position.balances, idx);
            balance.last_acc_rewards_per_share_x64
        } else {
            0
        };

        // Does not overflow because `rewards_per_share` * `position.shares` < `2^64`.
        let amt = (
            *to_acc_rewards_per_share_x64 - from_acc_rewards_per_share_x64
        ) * (position.shares as u256) / (Q64 as u256);

        (amt as u64)
    }

    /// ** Do not call before asserting `position.ad_id` matches `self.id`! **
    /// Update position rewards value to current amount for a single currency type. `O(1)`.
    fun update_position_single(
        self: &AccumulationDistributor, position: &mut Position, idx: u64
    ) {
        let unlockable_amt = calc_position_unlockable_rewards_idx(self, position, idx);

        let (_, balance) = vec_map::get_entry_by_idx_mut(&mut position.balances, idx);
        let (_, to_acc_rewards_per_share_x64) = vec_map::get_entry_by_idx(
            &self.acc_rewards_per_share_x64, idx
        );

        balance.available_rewards = balance.available_rewards + unlockable_amt;
        balance.last_acc_rewards_per_share_x64 = *to_acc_rewards_per_share_x64;
    }

    /// ** Do not call before asserting `position.ad_id` matches `self.id`! **
    /// Update position reward values to current amounts for all currency types. `O(n)`.
    fun update_position(
        self: &AccumulationDistributor, position: &mut Position
    ) {
        position_add_missing_balances(self, position);

        let i = 0;
        let n = vec_map::size(&self.acc_rewards_per_share_x64);
        while (i < n) {
            update_position_single(self, position, i);

            i = i + 1;
        }
    }

    /// Deposit additional shares to an existing position.
    public fun deposit_shares(
        self: &mut AccumulationDistributor, position: &mut Position, amount: u64,
    ) {
        assert!(object::uid_as_inner(&self.id) == &position.ad_id, EInvalidPosition);

        update_position(self, position);

        self.total_shares = self.total_shares + amount;
        position.shares = position.shares + amount;
    }

    /// Withdraw shares from a position.
    public fun withdraw_shares(
        self: &mut AccumulationDistributor, position: &mut Position, amount: u64
    ) {
        assert!(object::uid_as_inner(&self.id) == &position.ad_id, EInvalidPosition);
        assert!(position.shares >= amount, ENotEnough);

        update_position(self, position);

        self.total_shares = self.total_shares - amount;
        position.shares = position.shares - amount;
    }

    /// Merge two positions into a single.
    public fun merge_positions(
        self: &mut AccumulationDistributor, into: &mut Position, from: Position
    ) {
        let id = object::uid_as_inner(&self.id);
        assert!(&from.ad_id == id, EInvalidPosition);
        assert!(&into.ad_id == id, EInvalidPosition);

        update_position(self, &mut from);
        update_position(self, into);

        let i = 0;
        let n = vec_map::size(&into.balances);
        while (i < n) {
            let idx = n - 1 - i;

            let (_, from_bal) = vec_map::pop(&mut from.balances);
            let (_, to_bal) = vec_map::get_entry_by_idx_mut(&mut into.balances, idx);

            to_bal.available_rewards = to_bal.available_rewards + from_bal.available_rewards;

            let PositionBalance {
                available_rewards: _, last_acc_rewards_per_share_x64: _
            } = from_bal;

            i = i + 1;
        };
        into.shares = into.shares + from.shares;

        let Position { ad_id: _, shares: _, balances} = from;
        vec_map::destroy_empty(balances);
    }

    /// Destroy a position. All rewards and shares must be withdrawn before calling this.
    public fun position_destroy_empty(position: Position) {
        assert!(position.shares == 0, ENotEmpty);

        let Position { ad_id: _, shares: _, balances} = position;

        let i = 0;
        let n = vec_map::size(&balances);
        while (i < n) {
            let (_, balance) = vec_map::pop(&mut balances);
            let PositionBalance {
                available_rewards,
                last_acc_rewards_per_share_x64: _
            } = balance;

            assert!(available_rewards == 0, ENotEmpty);

            i = i + 1;
        };

        vec_map::destroy_empty(balances);
    } 

    /// Withdraw rewards without updating the position w.r.t. the current distributor state.
    /// This is possible since reward amounts unlocked at previous updates are internally cached.
    /// This operation is cheap but full reward amount may not be available through this function
    /// (only up to the value returned by `position_reward_value_direct` function).
    public fun withdraw_rewards_direct<T>(
        self: &mut AccumulationDistributor, position: &mut Position, amount: u64
    ): Balance<T> {
        assert!(object::uid_as_inner(&self.id) == &position.ad_id, EInvalidPosition);

        position_add_missing_balances(self, position);

        let type = type_name::get<T>();
        let idx = vec_map::get_idx(&position.balances, &type);

        let (_, position_bal) = vec_map::get_entry_by_idx_mut(&mut position.balances, idx);
        let balance = bag::borrow_mut<TypeName, Balance<T>>(&mut self.balances, type);

        assert!(position_bal.available_rewards >= amount, ENotEnough);
        position_bal.available_rewards = position_bal.available_rewards - amount;

        balance::split(balance, amount)
    }

    /// Withdraw `amount` of rewards of type `T` from the position.
    public fun withdraw_rewards<T>(
        self: &mut AccumulationDistributor, position: &mut Position, amount: u64
    ): Balance<T> {
        assert!(object::uid_as_inner(&self.id) == &position.ad_id, EInvalidPosition);

        position_add_missing_balances(self, position);

        let type = type_name::get<T>();
        let idx = vec_map::get_idx(&position.balances, &type);

        // update if needed
        let (_, position_bal) = vec_map::get_entry_by_idx_mut(&mut position.balances, idx);
        if (position_bal.available_rewards < amount) {
            update_position_single(self, position, idx);
        };

        let (_, position_bal) = vec_map::get_entry_by_idx_mut(&mut position.balances, idx);
        let balance = bag::borrow_mut<TypeName, Balance<T>>(&mut self.balances, type);

        assert!(position_bal.available_rewards >= amount, ENotEnough);
        position_bal.available_rewards = position_bal.available_rewards - amount;

        balance::split(balance, amount)
    }

    /// Withdraw all rewards of type `T` from the position.
    public fun withdraw_all_rewards<T>(
        self: &mut AccumulationDistributor, position: &mut Position
    ): Balance<T> {
        assert!(object::uid_as_inner(&self.id) == &position.ad_id, EInvalidPosition);

        position_add_missing_balances(self, position);

        let type = type_name::get<T>();
        let idx = vec_map::get_idx(&position.balances, &type);
        update_position_single(self, position, idx);

        let (_, position_bal) = vec_map::get_entry_by_idx_mut(&mut position.balances, idx);
        let balance = bag::borrow_mut<TypeName, Balance<T>>(&mut self.balances, type);

        let amount = position_bal.available_rewards;
        position_bal.available_rewards = 0;

        balance::split(balance, amount)
    }

    /* ================= test only ================= */

    #[test_only]
    use std::vector;

    #[test_only]
    public fun assert_balances_length(self: &AccumulationDistributor, len: u64) {
        assert!(bag::length(&self.balances) == len, 0);
    }

    #[test_only]
    public fun assert_balance_value<T>(self: &AccumulationDistributor, value: u64) {
        let key = type_name::get<T>();
        let balance: &Balance<T> = bag::borrow(&self.balances, key);

        assert!(balance::value(balance) == value, 0);
    }

    #[test_only]
    public fun destroy_balance_for_testing<T>(self: &mut AccumulationDistributor) {
        let key = type_name::get<T>();
        let balance: Balance<T> = bag::remove(&mut self.balances, key);
        balance::destroy_for_testing(balance);
    }

    #[test_only]
    public fun assert_and_destroy_balance<T>(self: &mut AccumulationDistributor, value: u64) {
        let key = type_name::get<T>();
        let balance: Balance<T> = bag::remove(&mut self.balances, key);

        assert!(balance::value(&balance) == value, 0);

        balance::destroy_for_testing(balance);
    }

    #[test_only]
    public fun assert_extraneous_balances_length(self: &AccumulationDistributor, len: u64) {
        assert!(bag::length(&self.extraneous_balances) == len, 0);
    }

    #[test_only]
    public fun assert_extraneous_balance_value<T>(self: &AccumulationDistributor, value: u64) {
        let key = type_name::get<T>();
        let balance: &Balance<T> = bag::borrow(&self.extraneous_balances, key);

        assert!(balance::value(balance) == value, 0);
    }

    #[test_only]
    public fun destroy_extraneous_balance_for_testing<T>(self: &mut AccumulationDistributor) {
        balance::destroy_for_testing<T>(remove_extraneous_balance(self));
    }

    #[test_only]
    public fun assert_and_destroy_extraneous_balance<T>(self: &mut AccumulationDistributor, value: u64) {
        let key = type_name::get<T>();
        let balance: Balance<T> = bag::remove(&mut self.extraneous_balances, key);

        assert!(balance::value(&balance) == value, 0);

        balance::destroy_for_testing(balance);
    }

    #[test_only]
    public fun destroy_for_testing(self: AccumulationDistributor) {
        let AccumulationDistributor {
            id,
            balances,
            acc_rewards_per_share_x64: _,
            total_shares: _,
            extraneous_balances
        } = self;

        object::delete(id);
        bag::destroy_empty(balances);
        bag::destroy_empty(extraneous_balances);
    }

    #[test_only]
    public fun assert_acc_rewards_per_share_x64(
        self: &AccumulationDistributor,
        types: vector<TypeName>, 
        values: vector<u256>
    ) {
        let len = vec_map::size(&self.acc_rewards_per_share_x64);
        assert!(vector::length(&types) == len, 0);
        assert!(vector::length(&values) == len, 0);

        let i = 0;
        while (i < len) {
            let (act_k, act_v)  = vec_map::get_entry_by_idx(&self.acc_rewards_per_share_x64, i);
            assert!(vector::borrow(&types, i) == act_k, 0);
            assert!(vector::borrow(&values, i) == act_v, 0);

            i = i + 1;
        }
    }

    #[test_only]
    public fun assert_total_shares(self: &AccumulationDistributor, val: u64) {
        assert!(self.total_shares == val, 0);
    }

    #[test_only]
    public fun assert_position_shares(position: &Position, val: u64) {
        assert!(position.shares == val, 0)
    }

    #[test_only]
    public fun assert_position_balances_length(position: &Position, len: u64) {
        assert!(vec_map::size(&position.balances) == len, 0)
    }

    #[test_only]
    public fun assert_position_balances(
        position: &Position,
        types: vector<TypeName>, 
        available_rewards: vector<u64>,
        last_acc_rewards_per_share_x64: vector<u256>
    ) {
        let len = vec_map::size(&position.balances);
        assert!(vector::length(&types) == len, 0);
        assert!(vector::length(&available_rewards) == len, 0);
        assert!(vector::length(&last_acc_rewards_per_share_x64) == len, 0);

        let i = 0;
        while (i < len) {
            let (act_type, balance)  = vec_map::get_entry_by_idx(&position.balances, i);
            assert!(vector::borrow(&types, i) == act_type, 0);
            assert!(vector::borrow(&available_rewards, i) == &balance.available_rewards, 0);
            assert!(
                vector::borrow(&last_acc_rewards_per_share_x64, i) == &balance.last_acc_rewards_per_share_x64, 0
            );

            i = i + 1;
        }
    }
}
