import chai from "chai";
import chaiAsPromised from "chai-as-promised";
import { Address, ID } from "../../library-sui/src/v3/types";
import { ADMIN, CONFIG, ONCHAIN_CALLS, QUERY_CHAIN, SUI_CLIENT } from "../../env";
import { bigNumber, BigNumberable, CoinUtils } from "../../library-sui/dist";
import { BN, Keypair, TransactionBlock } from "../../library-sui/src/types";
import { sleep, SuiBlocks, toBigNumberStr, Transaction } from "../../library-sui/src";
import { CoinAmounts, TickMath } from "../../library-sui/src/spot/clmm";
import {
    getLiquidityParams,
    IPool,
    IPoolCompleteState,
    IPositionOpenEvent,
    priceToTick,
} from "../../library-sui/src/spot";

chai.use(chaiAsPromised);
export const expect = chai.expect;

export async function provideCoins(
    coinSymbol: string,
    account: Address,
    amount: BigNumberable,
    admin?: Keypair
): Promise<void> {
    const coinDetails = CONFIG.coins[coinSymbol];

    if (!coinDetails) {
        throw `Unable to provide coins. Please make sure that the coin "${coinSymbol}" exists in "./config.json"`;
    }

    // don't fund the account if it has alot of funds
    const balance = await CoinUtils.getCoinBalance(SUI_CLIENT, account, coinDetails.type);
    if (bigNumber(balance).gte(bigNumber(amount))) return;

    const faucetSigner = admin || ADMIN;
    const txb = new TransactionBlock();
    txb.moveCall({
        arguments: [
            txb.object(coinDetails.treasuryCap!),
            txb.pure.u64(bigNumber(amount).toFixed(0)),
            txb.pure.address(account)
        ],
        target: `${coinDetails.package}::${coinSymbol.toLowerCase()}::mint`
    });

    const builtBlock = await SuiBlocks.buildTxBlock(txb, SUI_CLIENT, faucetSigner);
    const signedBlock = await SuiBlocks.signTxBlock(builtBlock, faucetSigner);
    await SuiBlocks.executeSignedTxBlock(signedBlock, SUI_CLIENT);

    await sleep(1000);
}

export async function provideLiquidityToPool(
    pool: IPoolCompleteState,
    lowerPrice: number,
    upperPrice: number,
    coinA: number,
    coinB: number,
    newPosition?: boolean,
    slippage = 1
): Promise<ID> {
    const positions = await QUERY_CHAIN.getUserPositions(ADMIN.toSuiAddress(), {
        pool: pool.id
    });
    let positionID;

    if (positions.length == 0 || newPosition == true) {
        const txResponse = await ONCHAIN_CALLS.openPosition(
            pool,
            priceToTick(pool, lowerPrice),
            priceToTick(pool, upperPrice)
        );
        positionID = (
            Transaction.getEvents(txResponse, "PositionOpened")[0] as IPositionOpenEvent
        ).position_id;
    } else {
        lowerPrice = TickMath.tickIndexToPrice(
            positions[0].lower_tick,
            pool.coin_a.decimals,
            pool.coin_b.decimals
        ).toNumber();
        upperPrice = TickMath.tickIndexToPrice(
            positions[0].upper_tick,
            pool.coin_a.decimals,
            pool.coin_b.decimals
        ).toNumber();
        positionID = positions[0].position_id;
    }

    const coinAmounts: CoinAmounts = {
        coinA: new BN(toBigNumberStr(coinA, pool.coin_a.decimals)),
        coinB: new BN(toBigNumberStr(coinB, pool.coin_b.decimals))
    };

    const liqParams = getLiquidityParams(
        pool,
        lowerPrice,
        upperPrice,
        coinAmounts,
        slippage
    );

    // console.dir(JSON.parse(JSON.stringify(liqParams)));

    // don't provide liquidity to the pool if there is already significant liquidity
    if (Number(pool.liquidity) >= liqParams.liquidity && newPosition != true)
        return positionID;

    await ONCHAIN_CALLS.provideLiquidity(pool, positionID, liqParams);

    return positionID;
}

export function get_pool(poolName: string): IPool {
    return ONCHAIN_CALLS.config.Pools
        ? ONCHAIN_CALLS.config.Pools[poolName]
        : ({} as any as IPool);
}
