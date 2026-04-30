import { ADMIN, CONFIG, DEPLOYMENT, ONCHAIN_CALLS, QUERY_CHAIN, SUI_CLIENT } from "../env";
import {  sleep, toBigNumber, toBigNumberStr, Transaction } from "../library-sui/src";
import {  IPoolCreatedEvent, ISwapEvent, ISwapParams, ISwapResultEvent, QueryChain } from "../library-sui/src/spot";
import { expect, provideCoins, provideLiquidityToPool } from "./helpers/utils";

describe("Swaps", () => {
    const params: ISwapParams = {
        pool: undefined as any,
        amountIn: toBigNumberStr(1, CONFIG.coins["BLUE"].decimals),
        aToB: true,
        byAmountIn: true,
        amountOut: 1,
        slippage: 0.05
    };

    before(async ()=> {
        params.pool = await QUERY_CHAIN.getPool(`BLUE/USDC`)

        await provideCoins("BLUE", ADMIN.toSuiAddress(), toBigNumber(10_000, CONFIG.coins["BLUE"].decimals));
        await provideCoins("USDC", ADMIN.toSuiAddress(), toBigNumber(1_000_000, CONFIG.coins["USDC"].decimals));
        await provideLiquidityToPool(params.pool, 4545, 5500, 10, 50000);
    });

    beforeEach(async () => {
        params.pool = await QUERY_CHAIN.getPool(`BLUE/USDC`)
    })


    it("should estimate the amounf of BLUE token for equivalent amount of USDC", async () => {

        let txResult = await ONCHAIN_CALLS.computeSwapResults(
            {
                ...params, 
                amountIn: toBigNumber(0.01, CONFIG.coins["BLUE"].decimals)
            },
            {dryRun: true}
        )
        expect(Transaction.getStatus(txResult)).to.be.equal("success");
    })

    it("should swap BLUE token for equivalent amount of USDC", async () => {

        let txResult = await ONCHAIN_CALLS.swapAssets(
            {
                ...params, 
                amountIn: toBigNumber(0.01, CONFIG.coins["BLUE"].decimals)
            },
            {dryRun: true}
        )

        expect(Transaction.getStatus(txResult)).to.be.equal("success");
    })


    it("should swap USDC token for equivalent amount of BLUE", async () => {

        const txResult = await ONCHAIN_CALLS.computeSwapResults(
            {
                ...params, 
                amountIn: toBigNumber(10, CONFIG.coins["USDC"].decimals),
                aToB: false,
            }
        )

        expect(Transaction.getStatus(txResult)).to.be.equal("success");
        
    })

    it("should get 1 BLUE token for any amount of USDC required", async () => {

        const swapParams = {
            ...params, 
            amountOut: toBigNumber(1, CONFIG.coins["BLUE"].decimals), 
            aToB: false, 
            byAmountIn: false
        };

        swapParams.amountIn = await ONCHAIN_CALLS.getEstimatedAmount(params);

        const txResult = await ONCHAIN_CALLS.computeSwapResults(swapParams);

        expect(Transaction.getStatus(txResult)).to.be.equal("success");
        
    })

    it("should show the is exceeded flag true when computing swap result for amount > available liquidity", async () => {
        
        const swapParams = {
            ...params, 
            amountOut: toBigNumberStr(15, CONFIG.coins["BLUE"].decimals), 
            aToB: false, 
            byAmountIn: false
        };


        const txResult = await ONCHAIN_CALLS.computeSwapResults(
            swapParams
        )

        const event = Transaction.getEvents(txResult, "SwapResult")[0] as ISwapResultEvent;

        expect(event.is_exceed).to.be.true;      
    })


    it("should buy BLUE from single price range", async ()=> {


        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            0, // 0 bps fee
            5000, // starting price,
        );
        
        const event = Transaction.getEvents(poolTx, "PoolCreated")[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(2000);

        const queryChain = new QueryChain(SUI_CLIENT, deployment);
        const pool = await queryChain.getPool("BLUE/USDC");
        
        await provideLiquidityToPool(pool, 4545, 5500, 1, 5000);

        await sleep(2000);


        const swapParams: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(42, pool.coin_b.decimals),
            aToB: false,
            byAmountIn: true,
            amountOut: 1,
            slippage: 0.05
        };

        const txResponse = await ONCHAIN_CALLS.computeSwapResults(swapParams);

        const swapEvent = Transaction.getEvents(txResponse, "SwapResult")[0] as ISwapResultEvent;

        // V3 book expects 8396875
        expect(swapEvent.amount_calculated).to.be.equal('8396714');

    });


    it("should buy BLUE from a single range when there are two identical price ranges", async ()=> {

        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            0, // 0 bps fee
            5000, // starting price,
        );
        
        const event = Transaction.getEvents(poolTx, "PoolCreated")[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(2000);

        const queryChain = new QueryChain(SUI_CLIENT, deployment);
        const pool = await queryChain.getPool("BLUE/USDC");
        
        await provideLiquidityToPool(pool, 4545, 5500, 1, 5000);
        await sleep(2000);
        await provideLiquidityToPool(pool, 4545, 5500, 1, 5000, true);
        await sleep(2000);

        const swapParams: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(42, pool.coin_b.decimals),
            aToB: false,
            byAmountIn: true,
            amountOut: 1,
            slippage: 0.1
        };

        const txResponse = await ONCHAIN_CALLS.computeSwapResults(swapParams);

        const swapEvent = Transaction.getEvents(txResponse, "SwapResult")[0] as ISwapResultEvent;

        // V3 book expects 8396875
        expect(swapEvent.amount_calculated).to.be.equal('8398356');

    });


    it("should buy BLUE from multiple price ranges", async ()=> {

        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            0, // 0 bps fee
            5000, // starting price,
        );
        
        const event = Transaction.getEvents(poolTx, "PoolCreated")[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(2000);

        const queryChain = new QueryChain(SUI_CLIENT, deployment);
        let pool = await queryChain.getPool("BLUE/USDC");
        
        await provideLiquidityToPool(pool, 4545, 5500, 1, 5000);
        await sleep(2000);

        pool = await queryChain.getPool("BLUE/USDC");
        await provideLiquidityToPool(pool, 4900, 5100, 1, 5000, true);
        await sleep(2000);

        pool = await queryChain.getPool("BLUE/USDC");
 
        const swapParams: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(10_000, pool.coin_b.decimals),
            aToB: false,
            byAmountIn: true,
            amountOut: 1,
            slippage: 0.1
        };

        const txResponse = await ONCHAIN_CALLS.computeSwapResults(swapParams);

        const swapEvent = Transaction.getEvents(txResponse, "SwapResult")[0] as ISwapResultEvent;

        expect(swapEvent.amount_calculated).to.be.equal('1944731117');

    });


    it("should buy BLUE when price ranges are partially overlapping", async ()=> {

        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            0, // 0 bps fee
            5000, // starting price,
        );
        
        const event = Transaction.getEvents(poolTx, "PoolCreated")[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(2000);

        const queryChain = new QueryChain(SUI_CLIENT, deployment);
        let pool = await queryChain.getPool("BLUE/USDC");
        
        await provideLiquidityToPool(pool, 4900, 5100, 1, 5000);
        await sleep(2000);

        pool = await queryChain.getPool("BLUE/USDC");
        await provideLiquidityToPool(pool, 4990, 5110, 1, 5000, true);
        await sleep(2000);

        pool = await queryChain.getPool("BLUE/USDC");
        

        const swapParams: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(10_000, pool.coin_b.decimals),
            aToB: false,
            byAmountIn: true,
            amountOut: 1,
            slippage: 0.1
        };

        const txResponse = await ONCHAIN_CALLS.computeSwapResults(swapParams);

        const swapEvent = Transaction.getEvents(txResponse, "SwapResult")[0] as ISwapResultEvent;

        expect(swapEvent.amount_calculated).to.be.equal('1978504235');

    });


    it("should buy USDC from one price range", async ()=> {


        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            0, // 0 bps fee
            5000, // starting price,
        );
        
        const event = Transaction.getEvents(poolTx, "PoolCreated")[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(2000);

        const queryChain = new QueryChain(SUI_CLIENT, deployment);
        const pool = await queryChain.getPool("BLUE/USDC");
        
        await provideLiquidityToPool(pool, 4545, 5500, 1, 5000);

        await sleep(2000);


        const swapParams: ISwapParams = {
            pool,
            amountIn: toBigNumberStr(0.01337, pool.coin_a.decimals),
            aToB: true,
            byAmountIn: true,
            amountOut: 1,
            slippage: 0.05
        };

        const txResponse = await ONCHAIN_CALLS.computeSwapResults(swapParams);

        const swapEvent = Transaction.getEvents(txResponse, "SwapResult")[0] as ISwapResultEvent;

        expect(swapEvent.amount_calculated).to.be.equal('66808387');

    });

    it("should perfrom a BLUE to USDC swap multiple times", async () => {

        {
            let txResult = await ONCHAIN_CALLS.swapAssets(
                {
                    ...params, 
                    amountIn: toBigNumber(0.01, CONFIG.coins["BLUE"].decimals)
                },
                {dryRun: false}
            )

            expect(Transaction.getStatus(txResult)).to.be.equal("success");
        }


        {
            let txResult = await ONCHAIN_CALLS.swapAssets(
                {
                    ...params, 
                    amountIn: toBigNumber(0.01, CONFIG.coins["BLUE"].decimals)
                },
                {dryRun: false}
            )

            expect(Transaction.getStatus(txResult)).to.be.equal("success");
        }
    })


    it("should perform slightly worst swap rate on second swap as liquidity of the pool is low", async () => {

        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            1,
            5000, // starting price,
        );
        
        const event = Transaction.getEvents(poolTx, "PoolCreated")[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(5000);

        const queryChain = new QueryChain(SUI_CLIENT, deployment);
        const pool = await queryChain.getPool("BLUE/USDC");
        
        await provideLiquidityToPool(pool, 4545, 5500, 0.1, 500);

        await sleep(5000);

        {
            let txResult = await ONCHAIN_CALLS.swapAssets(
                {
                    ...params, 
                    amountIn: toBigNumber(0.06, CONFIG.coins["BLUE"].decimals)
                },
                {dryRun: false}
            )

            const event = Transaction.getEvents(txResult, "AssetSwap")[0] as ISwapEvent;
            expect(Transaction.getStatus(txResult)).to.be.equal("success");
            console.dir(event);
        }

        {
            let txResult = await ONCHAIN_CALLS.swapAssets(
                {
                    ...params, 
                    amountIn: toBigNumber(0.05, CONFIG.coins["BLUE"].decimals)
                },
                {dryRun: false}
            )

            const event = Transaction.getEvents(txResult, "AssetSwap")[0] as ISwapEvent;
            expect(Transaction.getStatus(txResult)).to.be.equal("success");
            console.dir(event);

        }
    })
});