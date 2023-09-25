/// `Farm` is essentially a wrapper around `TimeDistributor` and implements permission functionality
/// on top of it with composability and flexibility in mind.
/// 
/// It's intended to be used with `Pool` (from the `token_distribution::pool` module) to enable yield farming
/// functionality where an amount of coins is allocated to be distributed across multiple different
/// pools in each of which any number of participants can deposit tokens to recieve a share of the
/// rewards (similar to liquidity mining functionality pioneered by SushiSwap and then implemented by
/// many other DeFi platforms also).
/// 
/// Nonetheless, it is not required to use this module with `Pool`. In order to add a member to a `Farm`,
/// one creates a `FarmMemberKey` (anyone is allowed to create it), and then an admin can add this key
/// to a `Farm` and adjust its weight. The owner of `FarmMemberKey` has the authority to withdraw
/// rewards distributed for that key. This setup allows for any custom implementation of `Pool` to
/// transparently work with this module.
/// 
/// A `FarmMemberKey` can be a member of multiple `Farms` at once and there is support for enforcing
/// atomic withdrawals from all the farms the key is a member of (implemented via the
/// `MemberWithdrawAllTicket` hot potato struct). This allows for `Pools` to distribute rewards
/// of multiple different token types simultaneously.
///
/// Usage:
/// ```
/// let (farm, admin_cap) = farm::create(balance, 1670758154, ctx);
/// 
/// let key = farm::create_member_key(ctx);
/// farm::add_member(&admin_cap, &mut farm, &mut key, 100, clock);
/// farm::change_unlock_per_second(&admin_cap, &mut farm, 50, clock);
/// 
/// /// some time later...
/// let balance = farm::mebmer_withdraw_all(&mut farm, &mut key, clock);
/// ```

module token_distribution::farm {
    use std::vector;
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::vec_set::{Self, VecSet};
    use sui::clock::Clock;
    use token_distribution::time_distributor::{Self as td, TimeDistributor};

    /* ================= errors ================= */

    /// The provided `AdminCap` doesn't have authority over this farm.
    const EInvalidAdminCap: u64 = 0;
    /// The key is locked. It's not possible to add / remove key from `Farm` during ticket withdrawal.
    const EKeyLocked: u64 = 1;
    /// The key is invalid.
    const EInvalidKey: u64 = 2;
    /// The ticket has already withdrawn from this pool.
    const EAlreadyWithdrawn: u64 = 3;
    /// The ticket has not withdrawn from *all* the pools the key is a member of.
    const ENotAllWithdrawn: u64 = 4;
    /// The key is still a member of one or more farms and cannot be destroyed.
    const EKeyHasMemberships: u64 = 5;
    /// The receipt has already been redeemed.
    const EReceiptSpent: u64 = 6;

    /* ================= AdminCap ================= */

    /// Capability that is used to give admin permissions over a farm.
    struct AdminCap has key, store {
        id: UID
    }

    /// Destroy an `AdminCap`. This operation is irreversible so use with caution.
    public fun destroy_admin_cap_irreversibly_i_know_what_im_doing(cap: AdminCap) {
        let AdminCap { id } = cap;
        object::delete(id);
    }

    /* ================= FarmMemberKey ================= */

    /// `FarmMemberKey` is used to join `Farms` and collect rewards they distribute.
    /// Any key can be a member of multiple different `Farms` simultaneously.
    struct FarmMemberKey has key, store {
        id: UID,
        unique_memberships: u16,
        locked: bool
    }

    /// Create a new `FarmMemberKey`.
    public fun create_member_key(ctx: &mut TxContext): FarmMemberKey {
        FarmMemberKey { id: object::new(ctx), unique_memberships: 0, locked: false }
    }

    /// Create a new `FarmMemberKey` and transfer it to TX sender.
    public fun create_and_transfer_member_key(ctx: &mut TxContext) {
        transfer::transfer(create_member_key(ctx), tx_context::sender(ctx));
    }

    /// Destroy a member key. Aborts if this key is a member of any `Farms`.
    public fun destroy_member_key(key: FarmMemberKey) {
        assert!(key.unique_memberships == 0, EKeyHasMemberships);

        let FarmMemberKey {id, unique_memberships: _, locked: _} = key;
        object::delete(id);
    }

    /// Return the number of `Farms` this key is a member of.
    public fun key_memberships(key: &FarmMemberKey): u16 {
        key.unique_memberships
    }

    /* ================= Farm ================= */

    /// `Farm` is essentially a wrapper around `TimeDistributor` that allows the admin to add
    /// members and change parameters and members (`FarmMemberKey` holders) to collect rewards.
    struct Farm<phantom T> has key, store {
        id: UID,
        admin_id: ID,
        td: TimeDistributor<T, ID>,
    }

    /// Create a new `Farm` with provided initial balance, unlock start timestamp (in seconds), and `AdminCap` that will be
    /// the admin for this `Farm`.
    public fun create<T>(
        balance: Balance<T>,
        unlock_start_ts_sec: u64,
        ctx: &mut TxContext
    ): (Farm<T>, AdminCap) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        let farm = Farm {
            id: object::new(ctx),
            admin_id: object::id(&admin_cap),
            td: td::create(balance, unlock_start_ts_sec)
        };
        (farm, admin_cap)
    }

    /// Entry function. Create a new `Farm` and share it.
    public fun create_and_share<T>(
        coin: Coin<T>,
        unlock_start_ts_sec: u64,
        ctx: &mut TxContext
    ): AdminCap {
        let balance = coin::into_balance(coin);
        let (farm, admin_cap) = create(balance, unlock_start_ts_sec, ctx); 
        transfer::share_object(farm);

        admin_cap
    }

    /// Check that the provided `AdminCap` is the admin for the `Farm`.
    public fun assert_admin_cap<T>(farm: &Farm<T>, cap: &AdminCap) {
        assert!(object::borrow_id(cap) == &farm.admin_id, EInvalidAdminCap)
    }

    /// Deposit additional balance into the distributor. This prolongs the duration of the distribution.
    /// Can be O(1) or O(n) (see `time_distributor::top_up`).
    public fun top_up_balance<T>(
        cap: &AdminCap, farm: &mut Farm<T>, balance: Balance<T>, clock: &Clock
    ) {
        assert_admin_cap(farm, cap);
        td::top_up(&mut farm.td, balance, clock);
    }

    /// Entry function. Deposit additional coins into the distributor. This prolongs the duration of
    /// the distribution. Can be O(1) or O(n) (see `time_distributor::top_up`).
    public fun top_up<T>(
        cap: &AdminCap, farm: &mut Farm<T>, coin: Coin<T>, clock: &Clock
    ) {
        top_up_balance(cap, farm, coin::into_balance(coin), clock);
    }

    /// Return the number of members in the `Farm`.
    public fun size<T>(self: &Farm<T>): u64 {
        td::size(&self.td)
    }

    /// Entry function. Add a member to the farm with the specified weight. The provided `FarmMemberKey`
    /// gets permission to collect the rewards. O(n).
    public fun add_member<T>(
        cap: &AdminCap,
        farm: &mut Farm<T>,
        key: &mut FarmMemberKey,
        weight: u32,
        clock: &Clock
    ) {
        assert_admin_cap(farm, cap);
        assert!(key.locked == false, EKeyLocked);

        td::add_member(&mut farm.td, object::id(key), weight, clock);
        key.unique_memberships = key.unique_memberships + 1;
    }

    /// Add multiple members to the farm with their respective weights and keys. O(n).
    // TODO: refactor when https://github.com/MystenLabs/sui/issues/6553 gets implemented
    public fun add_members<T>(
        cap: &AdminCap,
        farm: &mut Farm<T>,
        keys: &mut vector<FarmMemberKey>,
        weights: vector<u32>,
        clock: &Clock
    ) {
        assert_admin_cap(farm, cap);

        let ids = vector::empty();
        let i = 0;
        let n = vector::length(keys);
        while (i < n) {
            let key = vector::borrow_mut(keys, i);
            assert!(key.locked == false, EKeyLocked);
            key.unique_memberships = key.unique_memberships + 1;

            vector::push_back(&mut ids, object::id(key));

            i = i + 1;
        };

        td::add_members(&mut farm.td, ids, weights, clock)
    }

    /// Remove member from the `Farm` which will stop issuing rewards for it. Note that this function
    /// doesn't require an admin cap. Any `FarmMemberKey` holder can remove that key from the `Farm`. O(n).
    public fun remove_member<T>(
        farm: &mut Farm<T>,
        key: &mut FarmMemberKey,
        clock: &Clock
    ): Balance<T> {
        assert!(key.locked == false, EKeyLocked);

        let (_, bal) = td::remove_member(&mut farm.td, object::borrow_id(key), clock);
        key.unique_memberships = key.unique_memberships - 1;

        bal
    }

    /* ================= ForcefulRemovalReceipt ================= */

    struct ForcefulRemovalReceipt<phantom T> has key, store {
        id: UID,
        key_id: ID,
        balance: Balance<T>,
        spent: bool
    }

    /// Admin function. Remove member from `Farm` by referencing `FarmMemberKey`'s object id.
    /// This allows admin to remove a member without having to gain access to the respective `FarmMemberKey`.
    /// **NOTE**: Calling this function will cause key's `unique_memberships` count to be wrong which will
    /// make it impossible for the key to be used with ticket withdrawals (see `MemberWithdrawAllTicket`).
    /// To remediate that, the `ForcefulRemovalReceipt` shared at the end of this function needs to be redeemed by
    /// the key by calling the `redeem_forceful_removal_receipt`. O(n).
    public fun forcefully_remove_member<T>(
        cap: &AdminCap, farm: &mut Farm<T>, id: ID, clock: &Clock, ctx: &mut TxContext
    ) {
        assert_admin_cap(farm, cap);

        let (_, balance) = td::remove_member(&mut farm.td, &id, clock);

        let receipt = ForcefulRemovalReceipt {
            id: object::new(ctx),
            key_id: id,
            balance,
            spent: false
        };
        transfer::share_object(receipt);
    }

    /// Redeem `ForcefulRemovalReceipt` caused by forcefully removing a key from the `Farm`.
    /// This is required in order to make ticket withdrawals (`MemberWithdrawAllTicket`) work again
    /// after a `FarmMemberKey` has been forcefully removed from a `Farm` (the `unique_memberships` field
    /// in the key needs to be updated to the correct value).
    public fun redeem_forceful_removal_receipt<T>(
        receipt: &mut ForcefulRemovalReceipt<T>, key: &mut FarmMemberKey
    ): Balance<T> {
        assert!(receipt.spent == false, EReceiptSpent);
        assert!(&receipt.key_id == object::borrow_id(key), EInvalidKey);
        assert!(key.locked == false, EKeyLocked);

        // TODO: destroy receipt once shared object deletion lands https://github.com/MystenLabs/sui/issues/2083
        /*
        let ForcefulRemovalReceipt { id, key_id: _, balance } = receipt;
        object::delete(id);
        */
        let value = balance::value(&receipt.balance);
        let balance = balance::split(&mut receipt.balance, value);

        key.unique_memberships = key.unique_memberships - 1;
        receipt.spent = true;

        balance
    }

    /// Withdraw all available balance for a member providing its `FarmMemberKey`.
    public fun member_withdraw_all<T>(farm: &mut Farm<T>, key: &FarmMemberKey, clock: &Clock): Balance<T> {
        td::member_withdraw_all(&mut farm.td, object::borrow_id(key), clock)
    }

    /* ================= MemberWithdrawAllTicket ================= */

    /// A "hot potato" struct used to facilitate atomic `FarmMemberKey` withdrawals that guarantee that
    /// full withdrawals from all `Farms` the key is a member of have been done.
    /// NOTE: It's also possible to withdraw rewards from the `Farm` by using the `member_withdraw_all
    /// function directly just with the `FarmMemberKey`, but then it's up to the `FarmMemberKey` holder
    /// to make sure that its rewards are being collected correctly.
    struct MemberWithdrawAllTicket {
        key_id: ID,
        farm_ids: VecSet<ID>
    }

    /// Create a new `MemberWithdrawAllTicket`. This ticket can be disposed only when withdrawals from 
    /// all `Farms` the key is a member of have been done. Once a ticket has been created for a specific
    /// key, this key becomes "locked" and cannot be added to or removed from any `Farms` to guarantee safety.
    /// **NOTE**: The `MemberWithdrawAllTicket` gives permission to the holder to withdraw from `Farms`
    /// the key is a member of so it should be handled with care.
    public fun new_withdraw_all_ticket(key: &mut FarmMemberKey): MemberWithdrawAllTicket {
        assert!(key.locked == false, EKeyLocked);

        key.locked = true;

        MemberWithdrawAllTicket {
            key_id: object::id(key),
            farm_ids: vec_set::empty()
        }
    }

    /// Dispose of `MemberWithdrawTicket`. Aborts if withdrawals from all of the `Farms` the key is a member
    /// of haven't been done.
    public fun destroy_withdraw_all_ticket(
        ticket: MemberWithdrawAllTicket, key: &mut FarmMemberKey
    ) {
        assert!(ticket.key_id == object::id(key), EInvalidKey);
        assert!(vec_set::size(&ticket.farm_ids) == (key.unique_memberships as u64), ENotAllWithdrawn);

        let MemberWithdrawAllTicket { key_id: _, farm_ids: _ } = ticket;

        key.locked = false;
    }


    /// Withdraw all available balance for a member providing a `MemberWithdrawAllTicket`. Aborts if
    /// a withdrawal for this `Farm` using this ticket has already been done. O(n) worst case. If the key
    /// is a member of a lot of `Farms` this can also be a limitation due to `vec_set` lookups.
    public fun member_withdraw_all_with_ticket<T>(
        farm: &mut Farm<T>, ticket: &mut MemberWithdrawAllTicket, clock: &Clock
    ): Balance<T> {
        assert!(vec_set::contains(&ticket.farm_ids, object::borrow_id(farm)) == false, EAlreadyWithdrawn);

        vec_set::insert(&mut ticket.farm_ids, object::id(farm));

        td::member_withdraw_all(&mut farm.td, &ticket.key_id, clock)
    }

    /* ================= farm management functions ================= */

    /// Change member weights by their indexes in the internal `TimeDistributor` `vec_map`. O(n).
    public fun change_member_weights_by_idxs<T>(
        cap: &AdminCap, farm: &mut Farm<T>, idxs: vector<u64>, new_weights: vector<u32>, clock: &Clock
    ) {
        assert_admin_cap(farm, cap);
        td::change_weights_by_idxs(&mut farm.td, idxs, new_weights, clock);
    }

    /// Change member weight by object ID of its `FarmMemberKey`. O(n).
    public fun change_member_weight<T>(
        cap: &AdminCap, farm: &mut Farm<T>, key: ID, new_weight: u32, clock: &Clock
    ) {
        assert_admin_cap(farm, cap);
        td::change_weight(&mut farm.td, &key, new_weight, clock);
    }

    /// Change reward unlock per second. O(n).
    public fun change_unlock_per_second<T>(
        cap: &AdminCap, farm: &mut Farm<T>, new_unlock_per_second: u64, clock: &Clock
    ) {
        assert_admin_cap(farm, cap);
        td::change_unlock_per_second(&mut farm.td, new_unlock_per_second, clock);
    }

    /// Set reward distribution start time to a different timestamp. O(n).
    public fun change_unlock_start_ts_sec<T>(
        cap: &AdminCap, farm: &mut Farm<T>, new_start_ts_sec: u64, clock: &Clock
    ) {
        assert_admin_cap(farm, cap);
        td::change_unlock_start_ts_sec(&mut farm.td, new_start_ts_sec, clock);
    }

    /* ================= test only ================= */

    #[test_only]
    public fun destroy_for_testing<T>(farm: Farm<T>) {
        let Farm { id, admin_id: _, td} = farm;
        object::delete(id);
        td::destroy_for_testing(td);
    }
}