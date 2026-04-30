import { ADMIN, CONFIG, ONCHAIN_CALLS, QUERY_CHAIN } from "../env";
import { Transaction } from "../library-sui/dist";
import { sleep, toBigNumber, toBigNumberStr } from "../library-sui/src";
import { getLiquidityParams, ILiquidityProvidedEvent, ILiquidityRemoved, IPoolCompleteState, IPositionOpenEvent, priceToTick, ILiquidityParams } from "../library-sui/src/spot";
import { ClmmPoolUtil, CoinAmounts } from "../library-sui/src/spot/clmm";
import { BN } from "../library-sui/src/types";
import { ID } from "../library-sui/src/v3/types";
import { expect, provideCoins } from "./helpers/utils";


describe("Liquidity", () => {

    let positionID: ID;
    let pool: IPoolCompleteState;
    let coinAmounts: CoinAmounts;
    const lowerPrice = 4545;
    const upperPrice = 5500;
    let liquidityParams: ILiquidityParams;

    before(async ()=> {
        await provideCoins("BLUE", ADMIN.toSuiAddress(), toBigNumber(100_000, CONFIG.coins["BLUE"].decimals));
        await provideCoins("USDC", ADMIN.toSuiAddress(), toBigNumber(100_000, CONFIG.coins["USDC"].decimals));

        pool = await QUERY_CHAIN.getPool(`BLUE/USDC`);
       
        const positions = await QUERY_CHAIN.getUserPositions(ADMIN.toSuiAddress());
    
        if(positions.length == 0 || positions[0].liquidity != 0 ){

            const txResponse = await ONCHAIN_CALLS.openPosition(
                pool,
                priceToTick(pool, lowerPrice),
                priceToTick(pool, upperPrice),
            )        

            positionID = (Transaction.getEvents(txResponse, "PositionOpened")[0] as IPositionOpenEvent).position_id;
    
        } else {
            positionID = positions[0].position_id
        }

        coinAmounts = {
            coinA: new BN(toBigNumberStr(1, pool.coin_a.decimals)),
            coinB: new BN(toBigNumberStr(5000, pool.coin_b.decimals))
        }
        
        liquidityParams = getLiquidityParams(pool, lowerPrice, upperPrice, coinAmounts, 0.005);

    });

    beforeEach(async()=> {
        await sleep(1000);
    })
    

    it("should open a position and provide liquidity to in an single Tx Block", async () => {

        const txResponse = await ONCHAIN_CALLS.openPositionWithLiquidity(
            pool,
            liquidityParams,
            {dryRun: false}
        )
        expect(Transaction.getStatus(txResponse)).to.be.equal("success");

    })
    


    it("should provide liquidity to an opened position", async () => {
        
        const txResponse = await ONCHAIN_CALLS.provideLiquidity(
            pool,
            positionID,
            liquidityParams,
            {dryRun: true}
        )

        expect(Transaction.getStatus(txResponse)).to.be.equal("success");

        const event = Transaction.getEvents(txResponse, "LiquidityProvided")[0] as ILiquidityProvidedEvent;

        expect(+event.liquidity).to.be.equal(liquidityParams.liquidity);

    })


    it("should increase the liquidity of the position when providing liquidity twice", async () => {
        
        {
            const txResponse = await ONCHAIN_CALLS.provideLiquidity(
                pool,
                positionID,
                liquidityParams,
                {dryRun: false}
            )

            expect(Transaction.getStatus(txResponse)).to.be.equal("success");

            const event = Transaction.getEvents(txResponse, "LiquidityProvided")[0] as ILiquidityProvidedEvent;

            expect(+event.liquidity).to.be.equal(liquidityParams.liquidity);
        }

        await sleep(2000);

        {
            const txResponse = await ONCHAIN_CALLS.provideLiquidity(
                pool,
                positionID,
                liquidityParams,
                {dryRun: false}
            )

            expect(Transaction.getStatus(txResponse)).to.be.equal("success");

            const event = Transaction.getEvents(txResponse, "LiquidityProvided")[0] as ILiquidityProvidedEvent;

            expect(+event.liquidity).to.be.equal(liquidityParams.liquidity);
        }

        await sleep(1000);
        
        const details = await QUERY_CHAIN.getPositionDetails(positionID);
        expect(details.liquidity).to.be.equal(2*liquidityParams.liquidity);

    })

    it("should revert when trying to provide zero liquidity to a position", async ()=> { 
    
        await expect(
            ONCHAIN_CALLS.openPositionWithLiquidity(
                pool,
                {...liquidityParams, liquidity: 0},
                {dryRun: true}
        )).to.be.eventually.rejectedWith("1015");
    })


    it("should remove all liquidity from a position", async ()=> {

        const txResponse = await ONCHAIN_CALLS.openPosition(
            pool,
            liquidityParams.lowerTick,
            liquidityParams.upperTick,
            {dryRun: false}
        )
        
        const positionID = (Transaction.getEvents(txResponse, "PositionOpened")[0] as IPositionOpenEvent).position_id;

        await sleep(1000);
        
        await ONCHAIN_CALLS.provideLiquidity(
            pool,
            positionID,
            liquidityParams,
            {dryRun: false}
        )

        await sleep(1000);
            
        const resp = await ONCHAIN_CALLS.removeLiquidity(
            pool,
            positionID,
            liquidityParams,
            {dryRun: false}
        )

        expect(Transaction.getStatus(resp)).to.be.equal("success");

        const event = Transaction.getEvents(resp, "LiquidityRemoved")[0] as ILiquidityRemoved;

        expect(+event.liquidity).to.be.equal(liquidityParams.liquidity);

        await sleep(1000);

        const details = await QUERY_CHAIN.getPositionDetails(positionID);
        
        expect(details.liquidity).to.be.equal(0);

    });

    it("should revert when trying to remove more liquidity than a position has", async ()=> {

        const txResponse = await ONCHAIN_CALLS.openPosition(
            pool,
            liquidityParams.lowerTick,
            liquidityParams.upperTick,
            {dryRun: false}
        )
        
        const positionID = (Transaction.getEvents(txResponse, "PositionOpened")[0] as IPositionOpenEvent).position_id;

        await sleep(1000);
                
        await ONCHAIN_CALLS.provideLiquidity(
            pool,
            positionID,
            liquidityParams,
            {dryRun: false}
        )

        await sleep(1000);
            
        await expect(ONCHAIN_CALLS.removeLiquidity(
            pool,
            positionID,
            {...liquidityParams, liquidity: liquidityParams.liquidity + 1},
            {dryRun: true}
        )).to.be.rejectedWith("1015");
    });


    it("should revert when slippage exceeds when providing liquidity", async () => {        
        await expect (
            ONCHAIN_CALLS.provideLiquidity(
            pool,
            positionID,
            {...liquidityParams, minCoinAmounts:{coinA: coinAmounts.coinA.add(new BN(1e9)), coinB: coinAmounts.coinB.add(new BN(1e9))}},
            {dryRun: true}
        )).to.be.eventually.rejectedWith("1010");

    })

    it("should revert when slippage exceeds when removing liquidity", async () => {    
        
        await ONCHAIN_CALLS.provideLiquidity(
            pool,
            positionID,
            liquidityParams
        );

        await sleep(1000);
        
        await expect (
            ONCHAIN_CALLS.removeLiquidity(
            pool,
            positionID,
            {...liquidityParams, minCoinAmounts:{ 
                coinA: coinAmounts.coinA.add(new BN(1e9)), 
                coinB: coinAmounts.coinB.add(new BN(1e6))
            }},
            {dryRun: true}
        )).to.be.eventually.rejectedWith("1010");

    })


    it("should open a position and provide it liquidity with fixed token A amount", async () => {

        const lowerTick = priceToTick(pool, 5001);
        const upperTick = priceToTick(pool, 5010);
        const coinAmount = new BN(toBigNumberStr(1, pool.coin_a.decimals));
        const fix_amount_a = true;
        const slippage = 0.01
        const curSqrtPrice = new BN(pool.current_sqrt_price);

        const liquidityInput = ClmmPoolUtil.estLiquidityAndcoinAmountFromOneAmounts(
            lowerTick,
            upperTick,
            coinAmount,
            fix_amount_a,
            true,
            slippage,
            curSqrtPrice
        )

        const txResponse = await ONCHAIN_CALLS.openPositionWithFixedAmount(
            pool,
            lowerTick,
            upperTick,
            liquidityInput,
            {dryRun: true}
        );

        expect(Transaction.getStatus(txResponse)).to.be.equal("success");

        console.dir(Transaction.getEvents(txResponse, "LiquidityProvided")[0])

    })



})