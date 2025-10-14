import { ADMIN, CONFIG, ONCHAIN_CALLS, QUERY_CHAIN } from "../env";
import { Transaction } from "../library-sui/dist";
import { sleep, toBigNumber, toBigNumberStr } from "../library-sui/src";
import { getLiquidityParams, IPoolCompleteState, IPositionOpenEvent, priceToTick, toUnsignedTick } from "../library-sui/src/spot";
import { CoinAmounts } from "../library-sui/src/spot/clmm";
import { BN } from "../library-sui/src/types";
import { ID } from "../library-sui/src/v3/types";
import { expect, provideCoins } from "./helpers/utils";

describe("Position", () => {

    let positionID: ID;
    let pool: IPoolCompleteState;
    let coinAmounts: CoinAmounts;
    const lowerPrice = 4545;
    const upperPrice = 5500;

    before(async ()=> {
        await provideCoins("BLUE", ADMIN.toSuiAddress(), toBigNumber(10_000, CONFIG.coins["BLUE"].decimals));
        await provideCoins("USDC", ADMIN.toSuiAddress(), toBigNumber(10_000, CONFIG.coins["USDC"].decimals));

        pool = await QUERY_CHAIN.getPool(`BLUE/USDC`);
       
        const positions = await QUERY_CHAIN.getUserPositions(ADMIN.toSuiAddress());
    
        if(positions.length == 0){
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
    });

    beforeEach(async()=>{
        await sleep(1000);
    })


    it("should open a new position", async () => {

        const txResponse = await ONCHAIN_CALLS.openPosition(
            pool,
            priceToTick(pool, lowerPrice),
            priceToTick(pool, upperPrice),
            {dryRun: true}
        )
        expect(Transaction.getStatus(txResponse)).to.be.equal("success");
    })



    it("should close a position with liquidity", async () => {

        const liquidityParams = getLiquidityParams(pool, lowerPrice, upperPrice, coinAmounts, 0.05);

        const txResponse = await ONCHAIN_CALLS.openPositionWithLiquidity(
            pool,
            liquidityParams,
            {dryRun: false}
        )

        const positionID = (Transaction.getEvents(txResponse, "PositionOpened")[0] as IPositionOpenEvent).position_id;

        await sleep(2000);

        const txResponse2 = await ONCHAIN_CALLS.closePosition(
            pool,
            positionID
        );

        expect(Transaction.getStatus(txResponse2)).to.be.equal("success");
    })


    it("should close a position with no liquidity", async () => {

        const txResponse = await ONCHAIN_CALLS.openPosition(
            pool,
            priceToTick(pool, lowerPrice),
            priceToTick(pool, upperPrice),
            {dryRun: false}
        )

        const positionID = (Transaction.getEvents(txResponse, "PositionOpened")[0] as IPositionOpenEvent).position_id;

        // TODO: Create a method that waits until the position is available on chain        
        await sleep(2000);

        const txResponse2 = await ONCHAIN_CALLS.closePosition(
            pool,
            positionID
        );

        expect(Transaction.getStatus(txResponse2)).to.be.equal("success");
    })

    it("should close a position", async () => {
        
        const txResponse = await ONCHAIN_CALLS.openPosition(
            pool,
            priceToTick(pool, lowerPrice),
            priceToTick(pool, upperPrice),
            {dryRun: true}
        )
        expect(Transaction.getStatus(txResponse)).to.be.equal("success");
    })    


    
    it("should get all the positions owned by an account", async () => {

        const positions = await QUERY_CHAIN.getUserPositions(ADMIN.toSuiAddress());

        expect(positions.length).to.be.greaterThan(0);
    })

    
    it("should revert as the upper tick > max allowed upper tick", async ()=> { 

        await expect(ONCHAIN_CALLS.openPosition(
            pool,
            1, 
            887273,
            {dryRun: true}
        )).to.be.eventually.rejectedWith("1002");
    })

    it("should revert as the lower tick is > upper tick", async ()=> { 
        await expect(
            ONCHAIN_CALLS.openPosition(
                pool, 
                10, 
                5, 
                {dryRun: true})
            ).to.be.eventually.rejectedWith("1002");
    })

    it("should revert as the lower tick is > upper tick", async ()=> { 
        await expect(
            ONCHAIN_CALLS.openPosition(
                pool, 
                toUnsignedTick(-887273), 
                1, 
                {dryRun: true})
            ).to.be.eventually.rejectedWith("1002");
    })




    

});