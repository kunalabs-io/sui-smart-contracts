module klsp_init::init;

use access_management::access::ActionRequest;
use kai_leverage::equity::EquityTreasury;
use kai_leverage::supply_pool;

public struct PoolCreationTicket<phantom T, phantom ST> has key, store {
    id: UID,
    treasury: EquityTreasury<ST>,
}

public fun new_pool_creation_ticket<T, ST: drop>(
    treasury: EquityTreasury<ST>,
    ctx: &mut TxContext,
): PoolCreationTicket<T, ST> {
    PoolCreationTicket { id: object::new(ctx), treasury }
}

public fun create_pool<T, ST: drop>(
    ticket: PoolCreationTicket<T, ST>,
    ctx: &mut TxContext,
): ActionRequest {
    let PoolCreationTicket { id, treasury } = ticket;
    object::delete(id);
    supply_pool::create_pool<T, ST>(treasury, ctx)
}
