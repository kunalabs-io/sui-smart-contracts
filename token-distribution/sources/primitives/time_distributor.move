/// `TimeDistributor` is component that locks a `Balance<T>` and then distributes it over time to
/// multiple (arbitrary) members where each member recieves a share proportional to its "weight".
/// 
/// For example, if the distributor has a balance of 100 with an unlock rate of 10 per second and 2 members with
/// wieghts of 100 and 300, the the duration of the distribution will be 10 seconds and the members
/// will recieve 25 and 75 of the original balance respectively.
/// 
/// The difference between this module and `accumulation_distributor` is that here the distribution balance is
/// pre-allocated and distributed over time using the internal `time_locked_balance` continueously instead of
/// being distributed using manual top-ups discretely. Also, since member weights are all stored in the distributor
/// object, any member weight can be modified by the holder of the distributor object (but this also means there's
/// a limit to the number of members since most of the operations are `O(n)`).
///
/// This module doesn't implement any permission functionality and it's intended to be used as a
/// building block for other modules.  
/// 
/// Usage:
/// ```
/// // create time distributor
/// let td = td::create<SUI, ID>(balance, 10);
/// let id: ID = <...>;
/// td::add_member(&mut td, id, 100, clock);
/// td::change_unlock_per_second(&mut td, id, clock);
/// 
/// // after some time... member withdraw
/// let balance = member_withdraw_all(&mut td, &id, clock);
/// ```

module token_distribution::time_distributor {
    use std::vector;
    use sui::vec_map::{Self, VecMap};
    use sui::balance::{Self, Balance};
    use sui::math;
    use sui::clock::Clock;
    use token_distribution::time_locked_balance::{TimeLockedBalance};
    use token_distribution::time_locked_balance as tlb;
    use token_distribution::primitives_util::timestamp_sec;

    /// Weight must be > 0.
    const EZeroWeight: u64 = 0;
    /// Indexes and weights vector params lengths don't match.
    const EVecLenghtsDontMatch: u64 = 1;
    /// Indexes and weights vector params lengths are zero.
    const EVecZeroLength: u64 = 2;
    /// Setting unlock per second is not allowed when distributor has no members.
    const ENoMembers: u64 = 3;

    struct Member<phantom T> has store {
        weight: u32,
        unlocked_balance: Balance<T>,
        unlocked_since_update: u64
    }

    struct TimeDistributor<phantom T, K: copy> has store {
        tlb: TimeLockedBalance<T>,

        members: VecMap<K, Member<T>>,
        total_weight: u64,

        unlocked_balance: Balance<T>,
        update_ts_sec: u64,
    }

    /// Creates a new empty `TimeDistributor`.
    public fun create<T, K: copy>(
        balance: Balance<T>, unlock_start_ts: u64,
    ): TimeDistributor<T, K> {
        TimeDistributor {
            tlb: tlb::create(balance, unlock_start_ts, 0),
            members: vec_map::empty<K, Member<T>>(),
            total_weight: 0,
            unlocked_balance: balance::zero(),
            update_ts_sec: 0,
        }
    }

    /// Creates a new `TimeDistributor` with the specified members, unlock start ts, and unlock per second.
    public fun create_with_members<T, K: copy>(
        balance: Balance<T>,
        member_keys: vector<K>,
        member_weights: vector<u32>,
        unlock_start_ts: u64,
        unlock_per_second: u64,
        clock: &Clock
    ): TimeDistributor<T, K> {
        let self = create<T, K>(balance, unlock_start_ts);
        add_members(&mut self, member_keys, member_weights, clock);
        change_unlock_per_second(&mut self, unlock_per_second, clock);

        self
    }

    public fun unlock_per_second<T, K: copy>(self: &TimeDistributor<T, K>): u64 {
        tlb::unlock_per_second(&self.tlb)
    }

    public fun unlock_start_ts_sec<T, K: copy>(self: &TimeDistributor<T, K>): u64 {
        tlb::unlock_start_ts_sec(&self.tlb)
    }

    /// The value of extraneous balance (see `time_locked_balance` module docs for more details).
    /// This balance is retreivable using the `skim_extraneous_balance` function.
    public fun extraneous_locked_amount<T, K: copy>(self: &TimeDistributor<T, K>): u64 {
        tlb::extraneous_locked_amount(&self.tlb)
    }

    /// Withdraws all of the extraneous balance.
    public fun skim_extraneous_balance<T, K: copy>(self: &mut TimeDistributor<T, K>): Balance<T> {
        tlb::skim_extraneous_balance(&mut self.tlb)
    }

    /// Returns the timestamp at which the last unlock will be distributed to members.
    public fun final_unlock_ts_sec<T, K: copy>(self: &TimeDistributor<T, K>): u64 {
        tlb::final_unlock_ts_sec(&self.tlb)
    }

    /// Returns the number of members.
    public fun size<T, K: copy>(self: &TimeDistributor<T, K>): u64 {
        vec_map::size(&self.members)
    }
 
    /// Calculates (a * b) / c. Errors if result doesn't fit into u64.
    fun muldiv(a: u64, b: u64, c: u64): u64 {
        (((a as u128) * (b as u128)) / (c as u128) as u64)
    }

    // Releases the appropriate amount of balance from `self.unlocked_balance` to member. Assumes that
    // the required amount of balance for the current timestamp is available in `self.unlocked_balance` (i.e.
    // it's been released from `self.tlb` to `self.unlocked_balance`).
    fun member_unlock<T, K: copy>(
        self: &mut TimeDistributor<T, K>, idx: u64, clock: &Clock
    ) {
        let unlock_from_ts = math::max(self.update_ts_sec, tlb::unlock_start_ts_sec(&self.tlb));
        let unlock_until_ts = math::min(tlb::final_unlock_ts_sec(&self.tlb), timestamp_sec(clock));
        let unlock_per_second = tlb::unlock_per_second(&self.tlb);        

        let (_, member) = vec_map::get_entry_by_idx_mut(&mut self.members, idx);

        if (unlock_from_ts < unlock_until_ts) {
            let unlock_amt = muldiv(
                (unlock_until_ts - unlock_from_ts) * unlock_per_second, (member.weight as u64),
                (self.total_weight as u64)
            ) - member.unlocked_since_update;
            balance::join(
                &mut member.unlocked_balance,
                balance::split(&mut self.unlocked_balance, unlock_amt)
            );
            member.unlocked_since_update = member.unlocked_since_update + unlock_amt;
        }; 
    }

    // Does an O(n) update calling `member_unlock` for all members updating them to the current timestamp.
    // Also changes `self.update_ts_sec` to the current timestamp and sets `member.unlocked_since_update` to 0.
    // Due to rounding down this will often result in a remainder balance which will be topped up back to the `tlb`.
    fun update<T, K: copy>(
        self: &mut TimeDistributor<T, K>, clock: &Clock
    ) {
        let now = timestamp_sec(clock);
        if (self.update_ts_sec == now) {
            return
        };

        balance::join(
            &mut self.unlocked_balance,
            tlb::withdraw_all(&mut self.tlb, clock)
        );

        // TODO: this loop can be optimized since some values in `member_unlock` call
        // can be pre caluclated for all members.
        let i = 0;
        let n = vec_map::size(&self.members);
        while (i < n) {
            member_unlock(self, i, clock);

            let (_, member) = vec_map::get_entry_by_idx_mut(&mut self.members, i);
            member.unlocked_since_update = 0;

            i = i + 1;
        };  

        let val = balance::value(&self.unlocked_balance);
        tlb::top_up(
            &mut self.tlb,
            balance::split(&mut self.unlocked_balance, val),
            clock
        );

        self.update_ts_sec = now;
    }

    /// Add members to the distributor with specified keys and weights. O(n).
    /// Aborts if any of the provided member keys is already in the distributor.
    public fun add_members<T, K: copy>(
        self: &mut TimeDistributor<T, K>,
        member_keys: vector<K>,
        member_weights: vector<u32>,
        clock: &Clock
    ) {
        let len = vector::length(&member_keys);
        assert!(len > 0, EVecZeroLength);
        assert!(len == vector::length(&member_weights), EVecLenghtsDontMatch);

        update(self, clock);

        // reverse so that when `pop_back` is used in the loop, the members
        // are added in the correct order
        vector::reverse(&mut member_keys);
        vector::reverse(&mut member_weights);

        let i = 0;
        while (i < len) {
            let key = vector::pop_back(&mut member_keys);
            let weight = vector::pop_back(&mut member_weights);

            assert!(weight > 0, EZeroWeight);
            let new_member = Member {
                weight,
                unlocked_balance: balance::zero(),
                unlocked_since_update: 0
            };
            vec_map::insert(&mut self.members, key, new_member);

            self.total_weight = self.total_weight + (weight as u64);

            i = i + 1;
        };
        vector::destroy_empty(member_keys); 
    }

    /// Adds a member to the distributor with specified key and weight. O(n).
    /// Aborts if the specified key is already in the distributor.
    public fun add_member<T, K: copy>(
        self: &mut TimeDistributor<T, K>, key: K, weight: u32, clock: &Clock
    ) {
        add_members(self, vector::singleton(key), vector::singleton(weight), clock);
    }

    /// Removes a member by its index in the `self.members` `vec_map`. Returns any remaining
    /// member's unlocked balance. This operation is O(n) but all subsequent calls (at the same timestamp)
    /// are O(1).
    public fun remove_member_by_idx<T, K: copy>(
        self: &mut TimeDistributor<T, K>, idx: u64, clock: &Clock
    ): (K, Balance<T>) {
        update(self, clock);

        let (key, member) = vec_map::remove_entry_by_idx(&mut self.members, idx);
        let Member { weight, unlocked_balance, unlocked_since_update: _} = member;
        self.total_weight = self.total_weight - (weight as u64);

        if (self.total_weight == 0) {
            tlb::change_unlock_per_second(&mut self.tlb, 0, clock);
        };

        (key, unlocked_balance)
    }

    /// Removes a member by its key. Returns any remaining member's unlocked balance. O(n).
    public fun remove_member<T, K: copy>(
        self: &mut TimeDistributor<T, K>, key: &K, clock: &Clock
    ): (K, Balance<T>) {
        let idx = vec_map::get_idx(&mut self.members, key);
        remove_member_by_idx(self, idx, clock)
    }

    /// Change member weights by their indexes in the `self.members` `vec_map`. O(n).
    public fun change_weights_by_idxs<T, K: copy>(
        self: &mut TimeDistributor<T, K>, idxs: vector<u64>, new_weights: vector<u32>, clock: &Clock
    ) {
        let len = vector::length(&idxs);
        assert!(len == vector::length(&new_weights), EVecLenghtsDontMatch);
        assert!(len > 0, EVecZeroLength);

        update(self, clock);

        let p = 0;
        while(p < len) {
            let idx = *vector::borrow(&idxs, p);
            let new_weight = *vector::borrow(&new_weights, p);
            assert!(new_weight > 0, EZeroWeight);

            let (_, member) = vec_map::get_entry_by_idx_mut(&mut self.members, idx);
            self.total_weight = self.total_weight - (member.weight as u64) + (new_weight as u64);
            member.weight = new_weight;

            p = p + 1;
        };
    }

    /// Change member weight by its key. O(n).
    public fun change_weight<T, K: copy>(
        self: &mut TimeDistributor<T, K>, key: &K, new_weight: u32, clock: &Clock
    ) {
        let idx = vec_map::get_idx(&self.members, key);
        change_weights_by_idxs(self, vector::singleton(idx), vector::singleton(new_weight), clock);
    }

    /// Change distributor's balance distribution rate. O(n).
    /// Aborts if there are no members.
    public fun change_unlock_per_second<T, K: copy>(
        self: &mut TimeDistributor<T, K>, new_unlock_per_second: u64, clock: &Clock
    ) {
        if (new_unlock_per_second != 0) {
            assert!(self.total_weight > 0, ENoMembers);
        };

        update(self, clock);
        tlb::change_unlock_per_second(&mut self.tlb, new_unlock_per_second, clock);
    }

    /// Changes distribution start time. If the start time is changed to a future value when the distribution
    /// is currently active, it will effectively get paused until the new start time. The start time cannot be
    /// set before the current time (as in the `Clock` object). Attempting to set the time to an earlier value
    /// will default it to the current time. O(n).
    public fun change_unlock_start_ts_sec<T, K: copy>(
        self: &mut TimeDistributor<T, K>, new_start_ts_sec: u64, clock: &Clock
    ) {
        update(self, clock);
        tlb::change_unlock_start_ts_sec(&mut self.tlb, new_start_ts_sec, clock);
    }

    /// Adds additional balance to the distributor for distribution. This may prolong the distribution duration.
    /// This operation is O(1) if the `final_unlock_ts` hasn't yet been reached (distribution hasn't yet started
    /// or is still ongoing) and O(n) otherwise.
    public fun top_up<T, K: copy>(
        self: &mut TimeDistributor<T, K>, balance: Balance<T>, clock: &Clock
    ) {
        // restart unlocks if they have previously finished
        if (timestamp_sec(clock) > tlb::final_unlock_ts_sec(&self.tlb)) {
            update(self, clock);
        };
        tlb::top_up(&mut self.tlb, balance, clock);
    }

    /// Withdraw all available member unlocks by its index. O(1).
    public fun member_withdraw_all_by_idx<T, K: copy>(
        self: &mut TimeDistributor<T, K>, idx: u64, clock: &Clock
    ): Balance<T> {
        balance::join(
            &mut self.unlocked_balance,
            tlb::withdraw_all(&mut self.tlb, clock)
        );

        member_unlock(self, idx, clock);

        let (_, member) = vec_map::get_entry_by_idx_mut(&mut self.members, idx);
        let value = balance::value(&member.unlocked_balance);
        balance::split(
            &mut member.unlocked_balance, value
        )
    }

    /// Withdraw all available member unlocks by its key. O(n) worst case (`vec_map` key lookup).
    public fun member_withdraw_all<T, K: copy>(
        self: &mut TimeDistributor<T, K>, key: &K, clock: &Clock
    ): Balance<T> {
        let idx = vec_map::get_idx(&mut self.members, key);
        member_withdraw_all_by_idx(self, idx, clock)
    }

    #[test_only]
    public fun destroy_for_testing<T, K: copy>(
        self: TimeDistributor<T, K>
    ): vector<K> {
        let TimeDistributor {
            tlb,
            members,
            total_weight: _,
            unlocked_balance,
            update_ts_sec: _,
        } = self;

        tlb::destroy_for_testing(tlb);
        balance::destroy_for_testing(unlocked_balance);

        let (keys, members) = vec_map::into_keys_values(members);
        let i = 0;
        let n = vector::length(&members);
        while (i < n) {
            let member = vector::pop_back(&mut members);
            let Member { weight: _, unlocked_balance, unlocked_since_update: _} = member;

            balance::destroy_for_testing(unlocked_balance);

            i = i + 1;
        };
        vector::destroy_empty(members);

        keys
    }

    #[test_only]
    public fun get_values<T, K: copy>(
        self: &TimeDistributor<T, K>
    ): (u64, u64, u64) {
        (self.total_weight, balance::value(&self.unlocked_balance), self.update_ts_sec)
    }

    #[test_only]
    public fun assert_member_values<T, K: copy>(
        self: &TimeDistributor<T, K>,
        idx: u64, key: &K, weight: u32, unlocked_balance: u64, unlocked_since_update: u64
    ) {
        let (k, member) = vec_map::get_entry_by_idx(&self.members, idx);
        assert!(k == key, 0);
        assert!(member.weight == weight, 0);
        assert!(balance::value(&member.unlocked_balance) == unlocked_balance, 0);
        assert!(member.unlocked_since_update == unlocked_since_update, 0);
    }

    #[test_only]
    public fun assert_members_size<T, K: copy>(
        self: &TimeDistributor<T, K>, size: u64
    ) {
        assert!(size(self) == size, 0);
    }
}
