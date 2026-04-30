// import { ADMIN, CONFIG, ONCHAIN_CALLS, QUERY_CHAIN } from "../env";
// import { TransactionBlock } from "../library-sui/dist";
// import {  toBigNumber, toBigNumberStr, Transaction } from "../library-sui/src";
// import { IPoolCompleteState, ISwapRoute } from "../library-sui/src/spot";
// import { expect, get_pool, provideCoins, provideLiquidityToPool } from "./helpers/utils";

// describe("Swap Route", () => {
//     let pool: IPoolCompleteState;

//     before(async ()=> {
//         pool = await QUERY_CHAIN.getPool(`BLUE/USDC`);
//         await provideCoins("BLUE", ADMIN.toSuiAddress(), toBigNumber(10_000, CONFIG.coins["BLUE"].decimals));
//         await provideCoins("USDC", ADMIN.toSuiAddress(), toBigNumber(1_000_000, CONFIG.coins["USDC"].decimals));
//         await provideLiquidityToPool(pool, 4545, 5500, 10, 50000);
//     });

//     it("should execute swap route containing just one edge", async ()=> {

//         // A -> B 
//         const route: ISwapRoute = {
//             inputAmount: toBigNumberStr(0.1, CONFIG.coins["BLUE"].decimals),
//             outputAmount: toBigNumberStr(499, CONFIG.coins["USDC"].decimals),
//             fromCoin: pool.coinA,
//             toCoin: pool.coinB,
//             byAmountIn: true,
//             slippage: 5,
//             path: [
//                 {
//                     pool: `BLUE/USDC`,
//                     a2b: true,
//                     byAmountIn: true,
//                     amountIn: toBigNumberStr(0.1, CONFIG.coins["BLUE"].decimals),
//                     amountOut: toBigNumberStr(499, CONFIG.coins["USDC"].decimals)
//                 }
//             ]
//         };

//         const resp = await ONCHAIN_CALLS.executeSwapRoute(route, { dryRun: true});

//         expect(Transaction.getStatus(resp)).to.be.equal("success");
//     });

//     it("should execute swap route containing 2 edges", async ()=> {

//         // A -> B and B -> A
//         const route: ISwapRoute = {
//             inputAmount: toBigNumberStr(0.1, CONFIG.coins["BLUE"].decimals),
//             outputAmount: toBigNumberStr(0.1, CONFIG.coins["BLUE"].decimals),
//             fromCoin: pool.coinA,
//             toCoin: pool.coinA,
//             byAmountIn: true,
//             slippage: 10,
//             path: [
//                 {
//                     pool: `BLUE/USDC`,
//                     a2b: true,
//                     byAmountIn: true,
//                     amountIn: toBigNumberStr(0.1, CONFIG.coins["BLUE"].decimals),
//                     amountOut: toBigNumberStr(499, CONFIG.coins["USDC"].decimals)
//                 },
//                 {
//                     pool: `BLUE/USDC`,
//                     a2b: false,
//                     byAmountIn: true,
//                     amountIn: toBigNumberStr(499, CONFIG.coins["USDC"].decimals),
//                     amountOut: toBigNumberStr(0.1, CONFIG.coins["BLUE"].decimals)
//                 }
//             ]
//         };

//         const resp = await ONCHAIN_CALLS.executeSwapRoute(route, { dryRun: true});

//         expect(Transaction.getStatus(resp)).to.be.equal("success");

//     });

//     xit("should dev inspect the flash swap call", async ()=> {
//         const txb = new TransactionBlock();

//         txb.moveCall({
//             arguments: [
//                 txb.object(ONCHAIN_CALLS.config.GlobalConfig),
//                 txb.object(pool.id),
//                 txb.pure(true),
//                 txb.pure(true),
//                 txb.pure("100000000"),
//                 txb.pure("4295048016")
//             ],
//             target: `${ONCHAIN_CALLS.config.CurrentPackage}::pool::flash_swap`,
//             typeArguments: [pool.coinA, pool.coinB]
//         });

//         const resp = await ONCHAIN_CALLS.suiClient.devInspectTransactionBlock({
//             transactionBlock: txb,
//             sender: ONCHAIN_CALLS.walletAddress
//         });

//         const results = Transaction.getEvents(resp as any, "AssetSwap");
//         console.dir(results);

//     })

// });