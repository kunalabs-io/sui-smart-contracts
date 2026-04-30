import { ONCHAIN_CALLS, QUERY_CHAIN } from "../env";
import { BN, toBigNumberStr } from "../library-sui";
import { getMintParams } from "../library-sui/src/spot";
import { TickMath } from "../library-sui/src/spot/clmm";

async function main(){

    console.log("Providing liquidity to the pool")

    const pool = await QUERY_CHAIN.getPool(`SUI-USDC`);
    
    const amountA  = 5;
    const amountB  = 10;
    const lowerPrice  = 2;
    const upperPrice  = 2.5;

    const coinAmounts = {
        coinA: new BN(toBigNumberStr(amountA, pool.coin_a.decimals)),
        coinB: new BN(toBigNumberStr(amountB, pool.coin_b.decimals))
    }

    const liquidityParams = getMintParams(pool, lowerPrice, upperPrice, coinAmounts, 0.5);

    console.log(`Liquidity Params:`)
    console.dir(liquidityParams);


    await ONCHAIN_CALLS.openPositionWithLiquidity(
        `SUI-USDC`,
        liquidityParams,
        {dryRun: false}
    )

    // await ONCHAIN_CALLS.closePosition(pool, "0x9630e8416411e092157f12a390a4a8882945b2f8adfffa94e7fa950b6549a473");
}


if (require.main === module) {
    main();
}