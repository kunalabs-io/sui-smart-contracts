/// `TimeLockedBalance` locks a `Balance<T>` such that only `unlock_per_second` of the amount
/// gets unlocked (and becomes withdrawable) every second starting from `unlock_start_ts_sec`.
/// It allows for `unlock_per_second` and `unlock_start_ts_sec` to be safely changed and allows for aditional
/// balance to be added at any point via the `top_up` function.
///
/// This module doesn't implement any permission functionality and it is intended to be used
/// as a basic building block and to provide safety guarantees for building more complex token
/// emission modules (e.g. vesting).
/// 
module token_distribution::time_locked_balance {
    use sui::balance::{Self, Balance};
    use sui::math;
    use sui::clock::Clock;
    use token_distribution::primitives_util::timestamp_sec;

    /* ================= TimeLockedBalance ================= */

    /// Wraps a `Balance<T>` and allows only `unlock_per_second` of it to be withdrawn
    /// per second starting from `unlock_start_ts_sec`. All timestamp fields are unix timestamp.
    struct TimeLockedBalance<phantom T> has store {
        locked_balance: Balance<T>,
        unlock_start_ts_sec: u64,
        unlock_per_second: u64,

        /// Balance that gets unlocked and is withdrawable is stored here.
        unlocked_balance: Balance<T>,
        /// Time at which all of the balance will become unlocked. Unix timestamp.
        final_unlock_ts_sec: u64,

        previous_unlock_at: u64
    }

    public fun unlock_start_ts_sec<T>(self: &TimeLockedBalance<T>): u64 {
        self.unlock_start_ts_sec
    }

    public fun unlock_per_second<T>(self: &TimeLockedBalance<T>): u64 {
        self.unlock_per_second
    }

    public fun final_unlock_ts_sec<T>(self: &TimeLockedBalance<T>): u64 {
        self.final_unlock_ts_sec
    }

    public fun get_values<T>(self: &TimeLockedBalance<T>): (u64, u64, u64) {
        (self.unlock_start_ts_sec, self.unlock_per_second, self.final_unlock_ts_sec)
    }

    /* ================= main ================= */

    /// Creates a new `TimeLockedBalance<T>` that will start unlocking at `unlock_start_ts_sec` and
    /// unlock `unlock_per_second` of balance per second.
    public fun create<T>(
        locked_balance: Balance<T>, unlock_start_ts_sec: u64, unlock_per_second: u64
    ): TimeLockedBalance<T> {
        let final_unlock_ts_sec = calc_final_unlock_ts_sec(
            unlock_start_ts_sec, balance::value(&locked_balance), unlock_per_second
        );
        TimeLockedBalance {
            locked_balance,
            unlock_start_ts_sec,
            unlock_per_second,

            unlocked_balance: balance::zero<T>(),
            final_unlock_ts_sec,

            previous_unlock_at: 0
        }
    }

    /// Returns the value of extraneous balance.
    /// Since `locked_balance` amount might not be evenly divisible by `unlock_per_second`, there will be some
    /// extraneous balance. E.g. if `locked_balance` is 21 and `unlock_per_second` is 10, this function will
    /// return 1. Extraneous balance can be withdrawn by calling `skim_extraneous_balance` at any time.
    /// When `unlock_per_second` is 0, all balance in `locked_balance` is considered extraneous. This makes
    /// it possible to empty the `locked_balance` by setting `unlock_per_second` to 0 and then skimming.
    public fun extraneous_locked_amount<T>(self: &TimeLockedBalance<T>): u64 {
        if (self.unlock_per_second == 0) {
            balance::value(&self.locked_balance)
        } else {
            balance::value(&self.locked_balance) % self.unlock_per_second
        }
    }

    /// Returns the max. available amount that can be withdrawn at this time.
    public fun max_withdrawable<T>(self: &TimeLockedBalance<T>, clock: &Clock): u64 {
        balance::value(&self.unlocked_balance) + unlockable_amount(self, clock)
    }

    /// Returns the total amount of balance that is yet to be unlocked.
    public fun remaining_unlock<T>(self: &TimeLockedBalance<T>, clock: &Clock): u64 {
        let start = math::max(self.unlock_start_ts_sec, timestamp_sec(clock));
        if (start >= self.final_unlock_ts_sec) {
            return 0
        };

        (self.final_unlock_ts_sec - start) * self.unlock_per_second
    }

    /// Withdraws the specified (unlocked) amount. Errors if amount exceeds max. withdrawable.
    public fun withdraw<T>(self: &mut TimeLockedBalance<T>, amount: u64, clock: &Clock): Balance<T> {
        unlock(self, clock);
        balance::split(&mut self.unlocked_balance, amount)
    }

    /// Withdraws all available (unlocked) balance.
    public fun withdraw_all<T>(self: &mut TimeLockedBalance<T>, clock: &Clock): Balance<T> {
        unlock(self, clock);

        let amount = balance::value(&self.unlocked_balance);
        balance::split(&mut self.unlocked_balance, amount)
    }

    /// Adds additional balance to be distributed (i.e. prolongs the duration of distribution).
    public fun top_up<T>(self: &mut TimeLockedBalance<T>, balance: Balance<T>, clock: &Clock) {
        unlock(self, clock);

        balance::join(&mut self.locked_balance, balance);
        self.final_unlock_ts_sec = calc_final_unlock_ts_sec(
            math::max(self.unlock_start_ts_sec, timestamp_sec(clock)),
            balance::value(&self.locked_balance),
            self.unlock_per_second
        );
    }

    /// Changes `unlock_per_second` to a new value. New value is effective starting from the
    /// current timestamp (unlocks up to and including the current timestamp are based on the previous value).
    public fun change_unlock_per_second<T>(
        self: &mut TimeLockedBalance<T>, new_unlock_per_second: u64, clock: &Clock
    ) {
        unlock(self, clock);

        self.unlock_per_second = new_unlock_per_second;
        self.final_unlock_ts_sec = calc_final_unlock_ts_sec(
            math::max(self.unlock_start_ts_sec, timestamp_sec(clock)),
            balance::value(&self.locked_balance),
            new_unlock_per_second
        );
    }

    /// Changes `unlock_start_ts_sec` to a new value. If the new value is in the past, it will be set to
    /// the current time.
    public fun change_unlock_start_ts_sec<T>(
        self: &mut TimeLockedBalance<T>, new_unlock_start_ts_sec: u64, clock: &Clock
    ) {
        unlock(self, clock);

        let new_unlock_start_ts_sec = math::max(new_unlock_start_ts_sec, timestamp_sec(clock));
        self.unlock_start_ts_sec = new_unlock_start_ts_sec;
        self.final_unlock_ts_sec = calc_final_unlock_ts_sec(
            new_unlock_start_ts_sec,
            balance::value(&self.locked_balance),
            self.unlock_per_second
        );
    }

    /// Skims extraneous balance. Since `locked_balance` might not be evenly divisible by, and balance
    /// is unlocked only in the multiples of `unlock_per_second`, there might be some extra balance that will
    /// not be distributed (e.g. if `locked_balance` is 20 `unlock_per_second` is 10, the extraneous
    /// balance will be 1). This balance can be retrieved using this function.
    /// When `unlock_per_second` is set to 0, all of the balance in `locked_balance` is considered extraneous.
    public fun skim_extraneous_balance<T>(self: &mut TimeLockedBalance<T>): Balance<T> {
        let amount = extraneous_locked_amount(self);
        balance::split(&mut self.locked_balance, amount)
    }

    /// Destroys the `TimeLockedBalance<T>` when its balances are empty.
    public fun destroy_empty<T>(self: TimeLockedBalance<T>) {
        let TimeLockedBalance {
            locked_balance,
            unlock_start_ts_sec: _,
            unlock_per_second: _,
            unlocked_balance,
            final_unlock_ts_sec: _,
            previous_unlock_at: _
        } = self;
        balance::destroy_zero(locked_balance);
        balance::destroy_zero(unlocked_balance);
    }

    /* ================= util ================= */


    /// Helper function to calculate the `final_unlock_ts_sec`. Returns 0 when `unlock_per_second` is 0.
    fun calc_final_unlock_ts_sec(
        start_ts: u64,
        amount_to_issue: u64,
        unlock_per_second: u64,
    ): u64 {
        if (unlock_per_second == 0) {
            0
        } else {
            start_ts + (amount_to_issue / unlock_per_second)
        }
    }

    #[test]
    fun test_calc_final_unlock_ts_sec() {
        assert!(calc_final_unlock_ts_sec(100, 30, 20) == 101, 0);
        assert!(calc_final_unlock_ts_sec(100, 60, 30) == 102, 0);
        assert!(calc_final_unlock_ts_sec(100, 29, 30) == 100, 0);
        assert!(calc_final_unlock_ts_sec(100, 60, 0) == 0, 0);
        assert!(calc_final_unlock_ts_sec(100, 0, 20) == 100, 0);
        assert!(calc_final_unlock_ts_sec(100, 0, 0) == 0, 0);
    }

    /// Returns the amount of `locked_balance` that can be unlocked at this time.
    fun unlockable_amount<T>(self: &TimeLockedBalance<T>, clock: &Clock): u64 {
        if (self.unlock_per_second == 0) {
            return 0
        };
        let now = timestamp_sec(clock);
        if (now <= self.unlock_start_ts_sec) {
            return 0
        };

        let to_remain_locked = (
            self.final_unlock_ts_sec - math::min(self.final_unlock_ts_sec, now)
        ) * self.unlock_per_second;

        let locked_amount_round = 
            balance::value(&self.locked_balance) / self.unlock_per_second * self.unlock_per_second;

        locked_amount_round - to_remain_locked
    }

    /// Unlocks the balance that is unlockable based on the time passed since previous unlock.
    /// Moves the amount from `locked_balance` to `unlocked_balance`.
    fun unlock<T>(self: &mut TimeLockedBalance<T>, clock: &Clock) {
        let now = timestamp_sec(clock);
        if (self.previous_unlock_at == now) {
            return
        };

        let amount = unlockable_amount(self, clock);
        balance::join(&mut self.unlocked_balance, balance::split(&mut self.locked_balance, amount));

        self.previous_unlock_at = now;
    }

    /* ================= test only ================= */

    #[test_only]
    public fun destroy_for_testing<T>(self: TimeLockedBalance<T>) {
        let TimeLockedBalance {
            locked_balance,
            unlock_start_ts_sec: _,
            unlock_per_second: _,
            unlocked_balance,
            final_unlock_ts_sec: _,
            previous_unlock_at: _
        } = self;
        balance::destroy_for_testing(locked_balance);
        balance::destroy_for_testing(unlocked_balance);
    }

    #[test_only]
    public fun get_all_values<T>(self: &TimeLockedBalance<T>): (u64, u64, u64, u64, u64) {
        (
            balance::value(&self.locked_balance),
            self.unlock_start_ts_sec,
            self.unlock_per_second,
            balance::value(&self.unlocked_balance),
            self.final_unlock_ts_sec
        )
    }
}
