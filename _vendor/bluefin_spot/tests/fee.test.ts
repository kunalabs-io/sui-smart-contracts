import { ADMIN, CONFIG, DEPLOYMENT, ONCHAIN_CALLS, QUERY_CHAIN, SUI_CLIENT, } from "../env";
import {  sleep, toBaseNumber, toBigNumber, toBigNumberStr, Transaction } from "../library-sui/src";
import { getLiquidityParams, IPoolCompleteState, IPoolCreatedEvent, IPositionOpenEvent, ISwapEvent, ISwapParams, ISwapResultEvent, IUserFeeClaimedEvent, QueryChain } from "../library-sui/src/spot";
import { expect, get_pool, provideCoins, provideLiquidityToPool } from "./helpers/utils";
import { OnChainCalls } from "../library-sui/src/spot/on-chain-calls";
import { BN } from "../library-sui/src/types";
import { ID } from "../library-sui/src/v3/types";

describe("Swap Fee", () => {

    let pool:IPoolCompleteState;
    let position: ID;

    before(async ()=> {       
        pool = await QUERY_CHAIN.getPool(`BLUE/USDC`); 
        await provideCoins("BLUE", ADMIN.toSuiAddress(), toBigNumber(10_000, CONFIG.coins["BLUE"].decimals));
        await provideCoins("USDC", ADMIN.toSuiAddress(), toBigNumber(10_000, CONFIG.coins["USDC"].decimals));
        position = await provideLiquidityToPool(pool, 4545, 5000, 1, 5000);
    });

    beforeEach( async()=> {
        pool = await QUERY_CHAIN.getPool(`BLUE/USDC`);
    })

    it("should calculate fee in USDC when buying BLUE tokens", async ()=> {

        const params: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(42, pool.coin_a.decimals),
            aToB: false,
            byAmountIn: true,
            amountOut: 1,
            slippage: 1
        };

        const txResponse = await ONCHAIN_CALLS.computeSwapResults(params);

        const swapEvent = Transaction.getEvents(txResponse, "SwapResult")[0] as ISwapResultEvent;

        expect(swapEvent.fee_amount).to.be.equal('4200');

    });

    it("should calculate fee in BLUE when buying USDC tokens", async ()=> {

        const params: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(0.01337, pool.coin_a.decimals),
            aToB: true,
            byAmountIn: true,
            amountOut: 1,
            slippage: 1
        };

        const txResponse = await ONCHAIN_CALLS.computeSwapResults(params);

        const swapEvent = Transaction.getEvents(txResponse, "SwapResult")[0] as ISwapResultEvent;

        expect(swapEvent.fee_amount).to.be.equal('1337');

    });

    it("should split the fee 4200 into 70/30 for LPs and Protocol", async ()=> {


        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            1, // 1 bps fee
            5000, // starting price,
            { procolFeeShare: 0.3, dryRun: false}
        );
        
        const event = Transaction.getEvents(poolTx, "PooCreated")[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(2000);

        const queryChain = new QueryChain(SUI_CLIENT, deployment);
        const pool = await queryChain.getPool(`USDC/POOL`);

        await provideLiquidityToPool(pool, 4545, 5000, 1, 5000);


        const params: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(42, pool.coin_b.decimals),
            aToB: false,
            byAmountIn: true,
            amountOut: 1,
            slippage: 1
        };

        const onChain = new OnChainCalls(SUI_CLIENT, deployment, {signer: ADMIN});

        const txResponse = await onChain.computeSwapResults(params);

        const swapEvent = Transaction.getEvents(txResponse, "SwapResult")[0] as ISwapResultEvent;


        expect(swapEvent.fee_amount).to.be.equal('2940');
        expect(swapEvent.protocol_fee).to.be.equal('1260');

    });

    it("should collect zero fee from position as there is no fee owed to the user", async ()=> {

        const pool = await QUERY_CHAIN.getPool(`BLUE/USDC`);

        const coinAmounts = {
            coinA: new BN(toBigNumberStr(1, pool.coin_a.decimals)),
            coinB: new BN(toBigNumberStr(5000, pool.coin_b.decimals))
        }

        const liquidityParams = getLiquidityParams(pool, 4545, 5500, coinAmounts, 0.05);

        const txResponse = await ONCHAIN_CALLS.openPositionWithLiquidity(
            pool,
            liquidityParams,
            {dryRun: false}
        )

        const positionID = (Transaction.getEvents(txResponse, "PositionOpened")[0] as IPositionOpenEvent).position_id;
        await sleep(1000);

        {
            const txResponse = await ONCHAIN_CALLS.collectFee(pool, positionID);
            expect(Transaction.getStatus(txResponse)).to.be.equal("success");

            const event = Transaction.getEvents(txResponse, "UserFeeClaimed")[0] as IUserFeeClaimedEvent;
            expect(event.coin_a_amount).to.be.equal('0');
            expect(event.coin_b_amount).to.be.equal('0');
        }
        
    });


    it("should collect fee when there is any to collect", async ()=> {
        
        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            1, // 0 bps fee
            5000, // starting price,
        );
        
        const event = Transaction.getEvents(poolTx, "PoolCreated")[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(2000);

        const queryChain = new QueryChain(SUI_CLIENT, deployment);
        const pool = await queryChain.getPool("BLUE/USDC");
        
        const positionID = await provideLiquidityToPool(pool, 4545, 5500, 1, 5000, true);
        await sleep(2000);

        const swapParams: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(42, pool.coin_b.decimals),
            aToB: false,
            byAmountIn: true,
            amountOut: 1,
            slippage: 0.1
        };

        await ONCHAIN_CALLS.swapAssets(swapParams);
 
        await sleep(2000);

        const txResponse = await ONCHAIN_CALLS.collectFee(pool, positionID);
        expect(Transaction.getStatus(txResponse)).to.be.equal("success");

        const feeEvent = Transaction.getEvents(txResponse, "UserFeeCollected")[0] as IUserFeeClaimedEvent;
        expect(feeEvent.coin_a_amount).to.be.equal('0');
        expect(feeEvent.coin_b_amount).to.be.equal('3149');
        
    })

    it("should get the accrued fee by provided position", async ()=> {
        const feeAmounts = await ONCHAIN_CALLS.getAccruedFee(pool, position);
        const feeAmounCoinA = toBaseNumber(feeAmounts.coinA.toString(), 9, pool.coin_a.decimals);
        const feeAmounCoinB = toBaseNumber(feeAmounts.coinB.toString(), 9, pool.coin_b.decimals);
        console.log(`CoinA fee accrued by position: ${position} is ${feeAmounCoinA}`);
        console.log(`CoinB fee accrued by position: ${position} is ${feeAmounCoinB}`);
    });


    it("should get the accrued by provided positions", async ()=> {

        const feeAmounts = await ONCHAIN_CALLS.getAccruedFeeForPositions([{ pool, position }, { pool, position }]);

        feeAmounts.forEach((amounts) => {
            const feeAmounCoinA = toBaseNumber(amounts.coinA.toString(), 9, pool.coin_a.decimals);
            const feeAmounCoinB = toBaseNumber(amounts.coinB.toString(), 9, pool.coin_b.decimals);
            console.log(`CoinA fee accrued by position: ${position} is ${feeAmounCoinA}`);
            console.log(`CoinB fee accrued by position: ${position} is ${feeAmounCoinB}`);

        })

    });




});