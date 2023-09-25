/// `Pool` is a wrapper around `AccumulationDistributor` intended to be used with `Farm` to enable
/// any amount of participants to receive coin emissions proportional to their stake (shares in the pool).
/// 
/// A `Pool` can be a member of multiple `Farms` simultaneously which means that stake holders
/// can recieve rewards in multiple different currencies at once, but the currency used to provide
/// stake is limited only to one type `S`. Anyone is allowed to deposit shares into the pool.
/// 
/// Since a `Pool` can be a member of ultiple `Farms`, for correctness, a lot of operations require
/// `TopUpTicket` to be used. `TupUpTicket` is a wrapper arround `token_distribution::farm::MemberWithdrawAllTicket` and
/// guarantees that the pool is fully topped up with (potentially heterogeneous) balances from all the `Farms`
/// the pool is a member of. This is needed to guarantee the correctness of the reward amounts distributed
/// to each stake holder w.r.t. their share amount.
/// 
/// Usage:
/// ```
/// // create pool
/// let pool_cap = admin_cap::create(ctx);
/// let pool = pool::create<FOO>(&pool_cap, ctx);
/// pool::add_to_farm(&farm_cap, farm, &pool_cap, &mut pool, 100, clock);
/// 
/// // deposit shares
/// let ticket = pool::new_top_up_ticket ;
/// pool::top_up(farm, &mut pool, &mut ticket, clock);
/// let balance: Balance<FOO> = <...>;
/// let stake = pool::deposit_shares_new(&mut pool, balance, ticket, ctx);
/// 
/// // collect rewards (some time later)
/// let ticket = pool::new_top_up_ticket ;
/// pool::top_up(farm, &mut pool, &mut ticket, clock);
/// let balance = pool::collect_all_rewards(&mut pool, &mut stake, ticket);
/// ```

module token_distribution::pool {
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{TxContext};
    use sui::transfer;
    use sui::clock::Clock;
    use token_distribution::accumulation_distributor::{Self as acc, AccumulationDistributor, Position};
    use token_distribution::farm::{AdminCap as FarmAdminCap};
    use token_distribution::farm::{Self, Farm, FarmMemberKey, MemberWithdrawAllTicket, ForcefulRemovalReceipt};

    /* ================= errors ================= */

    /// The provided `AdminCap` doesn't have authority over this pool.
    const EInvalidAdminCap: u64 = 0;

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

    /* ================= Pool ================= */

    /// `Pool` is essentially a wrapper around `AccumulationDistributor` that is able to join a `Farm`
    /// as a member, collect rewards from its distribution, and then distribute them to its depositors
    /// (stake holders).
    struct Pool<phantom S> has key, store {
        id: UID,
        admin_id: ID,
        acc: AccumulationDistributor,
        farm_key: FarmMemberKey // never make it possible to borrow this
    }

    /// Create a new `Pool` where the provided `AdminCap` will be set as the admin.
    public fun create<S>(ctx: &mut TxContext): (Pool<S>, AdminCap) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        let pool = Pool {
            id: object::new(ctx),
            admin_id: object::id(&admin_cap),
            acc: acc::create(ctx),
            farm_key: farm::create_member_key(ctx)
        };
        (pool, admin_cap)
    }

    /// Create a new `Pool` and share it.
    public fun create_and_share<S>(ctx: &mut TxContext): AdminCap {
        let (pool, admin_cap) = create<S>(ctx);
        transfer::share_object(pool);

        admin_cap
    }

    /// Return the total amount of shares (stake) currently in the `Pool`.
    public fun total_shares<S>(pool: &Pool<S>): u64 {
        acc::total_shares(&pool.acc)
    }

    /// Check that the provided `AdminCap` is the admin for the `Pool`.
    fun assert_admin_cap<S>(self: &Pool<S>, cap: &AdminCap) {
        assert!(object::borrow_id(cap) == &self.admin_id, EInvalidAdminCap)
    }

    /// Add `Pool` to the `Farm` with the specified weight. Requires both pool and farm admin capabilities
    /// to be provided.
    public fun add_to_farm<T, S>(
        farm_cap: &FarmAdminCap,
        farm: &mut Farm<T>,
        pool_cap: &AdminCap,
        pool: &mut Pool<S>,
        weight: u32,
        clock: &Clock
    ) {
        assert_admin_cap(pool, pool_cap);
        farm::add_member(farm_cap, farm, &mut pool.farm_key, weight, clock);
    }

    /// Create a new `Pool` and add it to the `Farm` with the specified weight. Requires both pool and farm
    /// admin capabilities to be provided.
    public fun create_and_add_to_farm<T, S>(
        farm_cap: &FarmAdminCap, // admin of the farm
        farm: &mut Farm<T>,
        weight: u32,
        clock: &Clock,
        ctx: &mut TxContext
    ): AdminCap {
        let (pool, pool_cap) = create<S>(ctx);
        add_to_farm(farm_cap, farm, &pool_cap, &mut pool, weight, clock);
        transfer::share_object(pool);

        pool_cap
    }

    /// Remove the `Pool` from `Farm`. Requires the pool's `AdminCap`.
    public fun remove_from_farm<T, S>(
        cap: &AdminCap, farm: &mut Farm<T>, pool: &mut Pool<S>, clock: &Clock
    ) {
        assert_admin_cap(pool, cap);

        let balance = farm::remove_member(farm, &mut pool.farm_key, clock);
        acc::top_up(&mut pool.acc, balance);
    }

    /// Redeem a `farm::ForcefulRemovalReceipt` in case the `Pool` has been forcefully removed from
    /// a `Farm` by the farm admin. Any operations using `TopUpTicket` will not work until this is done.
    public fun redeem_forceful_removal_receipt<T, S>(
        self: &mut Pool<S>, receipt: &mut ForcefulRemovalReceipt<T>
    ) {
        let balance = farm::redeem_forceful_removal_receipt(receipt, &mut self.farm_key);
        acc::top_up(&mut self.acc, balance);
    }

    /* ================= Stake ================= */

    /// Represents a stake (deposited coins) in the `Pool`. Recieves rewards proportional to the
    /// total stake in the `Pool`.
    struct Stake<phantom S> has key, store {
        id: UID,
        position: Position,
        balance: Balance<S>
    }

    /// Return the amount of shares held in this `Stake`.
    public fun stake_balance<S>(stake: &Stake<S>): u64 {
        balance::value(&stake.balance)
    }

    /// Destroys an empty `Stake`. Aborts if there are still some shares or uncollected rewards held
    /// within it.
    public fun destroy_empty_stake<S>(stake: Stake<S>) {
        let Stake { id, position, balance } = stake;
        object::delete(id);
        balance::destroy_zero(balance);
        acc::position_destroy_empty(position);
    }

    /* ================= pool stake operations ================= */

    /// A wrapper around `farm::MemberWithdrawAllTicket` that guarantees that the pool has been correctly
    /// updated with rewards from all `Farms` it is a member of, even when it's added to an aditional `Farm`.
    /// A "hot potato".
    // NOTE: in theory, it would be safe to use the `Pool` even when it hasn't been fully updated with rewards
    // from all the `Farms`, but then this would have to be implemented on the client-side for the `Stake`s to
    // receive their rightful rewards in time. So for correctness and safety, this is done on the contract side.
    struct TopUpTicket {
        withdraw_all_ticket: MemberWithdrawAllTicket
    }
    
    /// Create a new `TopUpTicket`. This ticket can only be disposed only when the pool has been topped up with
    /// rewards from all `Farms` it is a member of. This is done by calling `top_up` on the pool with each of the
    /// farms it's a member of.
    public fun new_top_up_ticket<S>(pool: &mut Pool<S>): TopUpTicket {
        TopUpTicket {
            withdraw_all_ticket: farm::new_withdraw_all_ticket(&mut pool.farm_key)
        }
    }

    /// Destroy the `TopUpTicket`. Aborts if the pool has not been topped up with rewards collected from
    /// all the necessary farms.
    // This function is purpusefuly not public. Ticket can be only destroyed in deposit / withdraw functions
    // so that nobody can top up the pool directly. This may be changed in the future.
    fun destroy_top_up_ticket<S>(pool: &mut Pool<S>, ticket: TopUpTicket) {
        let TopUpTicket { withdraw_all_ticket } = ticket;
        farm::destroy_withdraw_all_ticket(withdraw_all_ticket, &mut pool.farm_key);
    }

    /// Collect rewards from the farm and top up the pool (internal `AccumulationDistributor`) with them to
    /// be distributed to stake holders. Providing the `TopUpTicket` "hot potato" is required in order to
    /// guarantee that the pool has been updated with all the required rewards.
    public fun top_up<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, ticket: &mut TopUpTicket, clock: &Clock
    ) {
        let balance = farm::member_withdraw_all_with_ticket(farm, &mut ticket.withdraw_all_ticket, clock);
        acc::top_up(&mut pool.acc, balance);
    }

    /// Deposit shares and create a new `Stake` object.
    public fun deposit_shares_new<S>(
        self: &mut Pool<S>, balance: Balance<S>, ticket: TopUpTicket, ctx: &mut TxContext
    ): Stake<S> {
        destroy_top_up_ticket(self, ticket); // this ensures the pool is fully topped up before continuing

        let amount = balance::value(&balance);
        Stake {
            id: object::new(ctx),
            position: acc::deposit_shares_new(&mut self.acc, amount),
            balance,
        }
    }

    /// Deposit additional shares to an existing `Position` in order to avoid creating a new `Position` object.
    public fun deposit_shares<S>(
        self: &mut Pool<S>, stake: &mut Stake<S>, balance: Balance<S>, ticket: TopUpTicket
    ) {
        destroy_top_up_ticket(self, ticket); // this ensures the pool is fully topped up before continuing

        let amount = balance::value(&balance);
        acc::deposit_shares(&mut self.acc, &mut stake.position, amount);

        balance::join(&mut stake.balance, balance);
    }

    /// Withdraw shares from the provided `Position`.
    public fun withdraw_shares<S>(
        self: &mut Pool<S>, stake: &mut Stake<S>, amount: u64, ticket: TopUpTicket
    ): Balance<S> {
        destroy_top_up_ticket(self, ticket); // this ensures the pool is fully topped up before continuing

        acc::withdraw_shares(&mut self.acc, &mut stake.position, amount);
        balance::split(&mut stake.balance, amount)
    }

    /// Merge two `Stake` objects (that belong to the same `Pool`) by combining their shares and rewards.
    public fun merge_stakes<S>(
        pool: &mut Pool<S>, into: &mut Stake<S>, from: Stake<S>
    ) {
       let Stake { id, position: from_position, balance: from_balance } = from;
       acc::merge_positions(&mut pool.acc, &mut into.position, from_position);

       object::delete(id);
       balance::join(&mut into.balance, from_balance);
    }

    /// Update the pool with new rewards collected from farms and then merge the `Stakes`.
    /// Effectively the same as withdrawing the `from` stake and depositing it into `into` stake.
    /// This can be better than caling `merge_stakes` in that it reduces the number of updates to
    /// the `Positions` when there are other operations that will be done on them immediately after.
    public fun update_and_merge_stakes<S>(
        pool: &mut Pool<S>, into: &mut Stake<S>, from: Stake<S>, ticket: TopUpTicket
    ) {
        destroy_top_up_ticket(pool, ticket); // this ensures the pool is fully topped up before continuing
        merge_stakes(pool, into, from);
    }

    /// Collect rewards directly available in the position without updating the pool using `TopUpTicket`.
    /// This is possible since reward amounts unlocket at previous updates are internally chached.
    /// This operation is cheap but full reward amount may not be available through this function.
    public fun collect_rewards_direct<T, S>(
        self: &mut Pool<S>, stake: &mut Stake<S>, amount: u64
    ): Balance<T> {
        acc::withdraw_rewards_direct(&mut self.acc, &mut stake.position, amount)
    }

    /// Collect `amount` of rewards from the `Position`.
    public fun collect_rewards<T, S>(
        self: &mut Pool<S>, stake: &mut Stake<S>, amount: u64, ticket: TopUpTicket
    ): Balance<T> {
        destroy_top_up_ticket(self, ticket); // this ensures the pool is fully topped up before continuing
        acc::withdraw_rewards(&mut self.acc, &mut stake.position, amount)
    }

    /// Collect all available rewards from the `Position`.
    public fun collect_all_rewards<T, S>(
        self: &mut Pool<S>, stake: &mut Stake<S>, ticket: TopUpTicket
    ): Balance<T> {
        destroy_top_up_ticket(self, ticket); // this ensures the pool is fully topped up before continuing
        acc::withdraw_all_rewards(&mut self.acc, &mut stake.position)
    }

    /* ================= test_only ================= */

    #[test_only]
    public fun destroy_for_testing<S>(pool: Pool<S>) {
        let Pool { id, admin_id: _, acc, farm_key } = pool;
        object::delete(id);
        acc::destroy_for_testing(acc);
        farm::destroy_member_key(farm_key);
    }

    #[test_only]
    public fun assert_stake_shares_amount<S>(stake: &Stake<S>, value: u64) {
        assert!(stake_balance(stake) == value, 0);
        acc::assert_position_shares(&stake.position, value);
    }

    #[test_only]
    public fun acc_assert_and_destroy_balance<T, S>(pool: &mut Pool<S>, value: u64) {
        acc::assert_and_destroy_balance<T>(&mut pool.acc, value);
    }

    #[test_only]
    public fun acc_assert_and_destroy_extraneous_balance<T, S>(pool: &mut Pool<S>, value: u64) {
        acc::assert_and_destroy_extraneous_balance<T>(&mut pool.acc, value);
    }

    #[test_only]
    public fun farm_key_id<S>(pool: &Pool<S>): ID {
        object::id(&pool.farm_key)
    }
}