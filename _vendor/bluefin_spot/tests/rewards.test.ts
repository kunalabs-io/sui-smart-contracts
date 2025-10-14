import {
    ADMIN,
    CONFIG,
    DEPLOYMENT,
    ONCHAIN_CALLS,
    QUERY_CHAIN,
    SUI_CLIENT
} from "../env";
import { sleep, toBigNumber, toBigNumberStr, Transaction } from "../library-sui/src";
import {
    getLiquidityParams,
    IPoolCompleteState,
    IPoolCreatedEvent,
    IPositionOpenEvent,
    IUpdatePoolRewardEmissionEvent,
    IUserRewardClaimedEvent,
    priceToTick,
    QueryChain
} from "../library-sui/src/spot";
import { expect, provideCoins, provideLiquidityToPool } from "./helpers/utils";
import { OnChainCalls } from "../library-sui/src/spot/on-chain-calls";
import { BigNumber, BN, getKeyPairFromPvtKey } from "../library-sui/dist";

describe("Spot rewards [Time sensitive tests, might fail if chain calls are slow] :", () => {
    let pool: IPoolCompleteState;
    let queryChain: QueryChain;

    before(async () => {
        await provideCoins(
            "BLUE",
            ADMIN.toSuiAddress(),
            toBigNumber(100_000, CONFIG.coins["BLUE"].decimals)
        );
        await provideCoins(
            "USDC",
            ADMIN.toSuiAddress(),
            toBigNumber(100_000, CONFIG.coins["USDC"].decimals)
        );
        // await provideLiquidityToPool(pool, 4545, 5500, 1, 5000, true);
    });

    beforeEach(async () => {
        const poolTx = await ONCHAIN_CALLS.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            0, // 0 bps fee
            5000 // starting price,
        );

        const event = Transaction.getEvents(
            poolTx,
            "PoolCreated"
        )[0] as IPoolCreatedEvent;

        const deployment = DEPLOYMENT;
        deployment.Pools["BLUE/USDC"].id = event.id;

        await sleep(2000);

        queryChain = new QueryChain(SUI_CLIENT, deployment);

        pool = await QUERY_CHAIN.getPool(`BLUE/USDC`);
    });

    describe("When adding rewards to the pools: ", () => {
        it("should allow pool manager to create USDC reward in pool", async () => {
            const rewardAmount = new BigNumber("1000000000");
            const rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 60;
            const rewardsActiveForSeconds = 300; //5 minutes

            const txResponse = await ONCHAIN_CALLS.addRewardCoinInPool({
                pool,
                startTime: rewardsStartTimeInSeconds,
                activeForSeconds: rewardsActiveForSeconds,
                rewardCoinType: CONFIG.coins["USDC"].type,
                rewardCoinAmount: rewardAmount,
                rewardCoinDecimals: CONFIG.coins["USDC"].decimals,
                rewardCoinSymbol: "USDC"
            });

            const rewardAddedEvent = Transaction.getEvents(
                txResponse,
                "UpdatePoolRewardEmissionEvent"
            )[0] as IUpdatePoolRewardEmissionEvent;

            expect(rewardAddedEvent.total_reward).to.be.equal(rewardAmount.toString());
        });

        it("should not allow creating rewards in pool with start time in past", async () => {
            const rewardAmount = new BigNumber("1000000000");

            const rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) - 60;
            const rewardsActiveForSeconds = 300; //5 minutes

            await expect(
                ONCHAIN_CALLS.addRewardCoinInPool({
                    pool,
                    startTime: rewardsStartTimeInSeconds,
                    activeForSeconds: rewardsActiveForSeconds,
                    rewardCoinType: CONFIG.coins["USDC"].type,
                    rewardCoinAmount: rewardAmount,
                    rewardCoinDecimals: CONFIG.coins["USDC"].decimals,
                    rewardCoinSymbol: "USDC"
                })
            ).to.be.eventually.rejectedWith("1020");
        });

        it("should not allow random wallet to create USDC reward in pool", async () => {
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb600",
                "Secp256k1"
            );

            await provideCoins(
                "USDC",
                WALLET.toSuiAddress(),
                toBigNumber(100_000, CONFIG.coins["USDC"].decimals)
            );

            const WALLET_ONCHAIN_CALLS = new OnChainCalls(SUI_CLIENT, DEPLOYMENT, {
                signer: WALLET
            });

            const rewardAmount = new BigNumber("1000000000");

            const rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 60;
            const rewardsActiveForSeconds = 300; //5 minutes

            await expect(
                WALLET_ONCHAIN_CALLS.addRewardCoinInPool({
                    pool,
                    startTime: rewardsStartTimeInSeconds,
                    activeForSeconds: rewardsActiveForSeconds,
                    rewardCoinType: CONFIG.coins["USDC"].type,
                    rewardCoinAmount: rewardAmount,
                    rewardCoinDecimals: CONFIG.coins["USDC"].decimals,
                    rewardCoinSymbol: "USDC"
                })
            ).to.be.eventually.rejectedWith("1023");
        });

        it("should allow pool manager to set a new pool manager", async () => {
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            const poolManager = WALLET.toSuiAddress();
            await ONCHAIN_CALLS.setPoolManager(pool, poolManager);

            const newManager = await ONCHAIN_CALLS.getPoolManager(pool);

            expect(newManager).to.be.equal(poolManager);
        });

        it("should not allow non-manager wallet to set a new pool manager", async () => {
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            const poolManager = WALLET.toSuiAddress();

            const WALLET_ONCHAIN_CALLS = new OnChainCalls(SUI_CLIENT, DEPLOYMENT, {
                signer: WALLET
            });

            await expect(
                WALLET_ONCHAIN_CALLS.setPoolManager(pool, poolManager)
            ).to.be.eventually.rejectedWith("1023");
        });

        it("should allow wallet whitelisted as reward manager to create USDC reward in pool", async () => {
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            const rewardsManager = WALLET.toSuiAddress();

            await ONCHAIN_CALLS.addRewardsManager(rewardsManager);

            await provideCoins(
                "USDC",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["USDC"].decimals)
            );

            const REWARD_MANAGER_ONCHAIN_CALLS = new OnChainCalls(
                SUI_CLIENT,
                DEPLOYMENT,
                {
                    signer: WALLET
                }
            );

            const rewardAmount = new BigNumber("1000000000");

            const rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 60;
            const rewardsActiveForSeconds = 300; //5 minutes

            const txResponse = await REWARD_MANAGER_ONCHAIN_CALLS.addRewardCoinInPool({
                pool,
                startTime: rewardsStartTimeInSeconds,
                activeForSeconds: rewardsActiveForSeconds,
                rewardCoinType: CONFIG.coins["USDC"].type,
                rewardCoinAmount: rewardAmount,
                rewardCoinDecimals: CONFIG.coins["USDC"].decimals,
                rewardCoinSymbol: "USDC"
            });

            const rewardAddedEvent = Transaction.getEvents(
                txResponse,
                "UpdatePoolRewardEmissionEvent"
            )[0] as IUpdatePoolRewardEmissionEvent;

            expect(rewardAddedEvent.total_reward).to.be.equal(rewardAmount.toString());
        });

        it("should not allow pool manager to create BLUE reward in pool", async () => {
            const rewardAmount = new BigNumber("1000000000000");

            const rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 60;
            const rewardsActiveForSeconds = 300; //5 minutes

            await expect(
                ONCHAIN_CALLS.addRewardCoinInPool({
                    pool,
                    startTime: rewardsStartTimeInSeconds,
                    activeForSeconds: rewardsActiveForSeconds,
                    rewardCoinType: CONFIG.coins["BLUE"].type,
                    rewardCoinAmount: rewardAmount,
                    rewardCoinDecimals: CONFIG.coins["BLUE"].decimals,
                    rewardCoinSymbol: "BLUE"
                })
            ).to.be.eventually.rejectedWith("1023");
        });

        it("should allow reward manager of protocol to create BLUE reward in pool", async () => {
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            const rewardsManager = WALLET.toSuiAddress();

            await ONCHAIN_CALLS.addRewardsManager(rewardsManager);

            await provideCoins(
                "BLUE",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["BLUE"].decimals)
            );

            const REWARD_MANAGER_ONCHAIN_CALLS = new OnChainCalls(
                SUI_CLIENT,
                DEPLOYMENT,
                {
                    signer: WALLET
                }
            );

            const rewardAmount = new BigNumber("1000000000000");

            const rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 60;
            const rewardsActiveForSeconds = 300; //5 minutes

            const txResponse = await REWARD_MANAGER_ONCHAIN_CALLS.addRewardCoinInPool({
                pool,
                startTime: rewardsStartTimeInSeconds,
                activeForSeconds: rewardsActiveForSeconds,
                rewardCoinType: CONFIG.coins["BLUE"].type,
                rewardCoinAmount: new BigNumber("0"),
                rewardCoinDecimals: CONFIG.coins["BLUE"].decimals,
                rewardCoinSymbol: "BLUE",
                blueRewardAmount: rewardAmount
            });

            const rewardAddedEvent = Transaction.getEvents(
                txResponse,
                "UpdatePoolRewardEmissionEvent"
            )[0] as IUpdatePoolRewardEmissionEvent;

            expect(rewardAddedEvent.total_reward).to.be.equal(rewardAmount.toString());
        });

        it("should be able to update reward emissions after reward intialization", async () => {
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            const rewardsManager = WALLET.toSuiAddress();

            await ONCHAIN_CALLS.addRewardsManager(rewardsManager);

            await provideCoins(
                "BLUE",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["BLUE"].decimals)
            );

            const REWARD_MANAGER_ONCHAIN_CALLS = new OnChainCalls(
                SUI_CLIENT,
                DEPLOYMENT,
                {
                    signer: WALLET
                }
            );

            const rewardAmount = new BigNumber("1000000000000");

            const rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 60;
            const rewardsActiveForSeconds = 300; //5 minutes

            const txResponse = await REWARD_MANAGER_ONCHAIN_CALLS.addRewardCoinInPool({
                pool,
                startTime: rewardsStartTimeInSeconds,
                activeForSeconds: rewardsActiveForSeconds,
                rewardCoinType: CONFIG.coins["BLUE"].type,
                rewardCoinAmount: new BigNumber("0"),
                rewardCoinDecimals: CONFIG.coins["BLUE"].decimals,
                rewardCoinSymbol: "BLUE",
                blueRewardAmount: rewardAmount
            });

            const rewardAddedEvent = Transaction.getEvents(
                txResponse,
                "UpdatePoolRewardEmissionEvent"
            )[0] as IUpdatePoolRewardEmissionEvent;

            expect(rewardAddedEvent.total_reward).to.be.equal(rewardAmount.toString());

            const txResponse2 =
                await REWARD_MANAGER_ONCHAIN_CALLS.updateRewardCoinEmission(
                    pool,
                    rewardsActiveForSeconds * 3,
                    CONFIG.coins["BLUE"].type,
                    new BigNumber("0"),
                    rewardAmount
                );

            const rewardAddedEvent2 = Transaction.getEvents(
                txResponse2,
                "UpdatePoolRewardEmissionEvent"
            )[0] as IUpdatePoolRewardEmissionEvent;

            expect(rewardAddedEvent2.total_reward).to.be.equal(
                rewardAmount.multipliedBy(new BigNumber("2")).toString()
            );

            expect(+rewardAddedEvent2.ended_at_seconds).to.be.equal(
                rewardsStartTimeInSeconds + rewardsActiveForSeconds * 4
            );

            // rewards allocation per second should reduce to half , as we are doubling reward amount but increasing time by 4
            const newRewardsPerSecond = new BigNumber(rewardAddedEvent.reward_per_seconds)
                .div(new BigNumber("2"));
            expect(newRewardsPerSecond.toString()).to.be.equal((new BigNumber(rewardAddedEvent2.reward_per_seconds)).toString());
        });

        it("should be able to add seconds to reward emissions after reward intialization", async () => {
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            const rewardsManager = WALLET.toSuiAddress();

            await ONCHAIN_CALLS.addRewardsManager(rewardsManager);

            await provideCoins(
                "BLUE",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["BLUE"].decimals)
            );

            const REWARD_MANAGER_ONCHAIN_CALLS = new OnChainCalls(
                SUI_CLIENT,
                DEPLOYMENT,
                {
                    signer: WALLET
                }
            );

            const rewardAmount = new BigNumber("1000000000000");

            const rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 60;
            const rewardsActiveForSeconds = 300; //5 minutes

            const txResponse = await REWARD_MANAGER_ONCHAIN_CALLS.addRewardCoinInPool({
                pool,
                startTime: rewardsStartTimeInSeconds,
                activeForSeconds: rewardsActiveForSeconds,
                rewardCoinType: CONFIG.coins["BLUE"].type,
                rewardCoinAmount: new BigNumber("0"),
                rewardCoinDecimals: CONFIG.coins["BLUE"].decimals,
                rewardCoinSymbol: "BLUE",
                blueRewardAmount: rewardAmount
            });

            const rewardAddedEvent = Transaction.getEvents(
                txResponse,
                "UpdatePoolRewardEmissionEvent"
            )[0] as IUpdatePoolRewardEmissionEvent;

            expect(rewardAddedEvent.total_reward).to.be.equal(rewardAmount.toString());

            const txResponse2 =
                await REWARD_MANAGER_ONCHAIN_CALLS.addSecondsToRewardCoinEmission(
                    pool,
                    rewardsActiveForSeconds,
                    CONFIG.coins["BLUE"].type
                );

            const rewardAddedEvent2 = Transaction.getEvents(
                txResponse2,
                "UpdatePoolRewardEmissionEvent"
            )[0] as IUpdatePoolRewardEmissionEvent;

            expect(+rewardAddedEvent2.ended_at_seconds).to.be.equal(
                rewardsStartTimeInSeconds + rewardsActiveForSeconds * 2
            );

            // rewards allocation per second should reduce to half , as we are doubling reward amount but increasing time by 4
            const newRewardsPerSecond = new BigNumber(rewardAddedEvent.reward_per_seconds)
                .div(new BigNumber("2"))
                .toString();
            expect(newRewardsPerSecond).to.be.equal(rewardAddedEvent2.reward_per_seconds);
        });
    });

    describe("[Time sensitive tests, might fail if chain calls are slow] After initializing USDC rewards, When adding liquidity in pool: ", () => {
        let rewardsStartTimeInSeconds;
        let rewardsActiveForSeconds;
        const rewardAmount = new BigNumber("10000000"); // 10 USDC
        beforeEach(async () => {
            rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 40; // 40 seconds in future
            rewardsActiveForSeconds = 5; // available for 5 seconds
            await ONCHAIN_CALLS.addRewardCoinInPool({
                pool,
                startTime: rewardsStartTimeInSeconds,
                activeForSeconds: rewardsActiveForSeconds,
                rewardCoinType: CONFIG.coins["USDC"].type,
                rewardCoinAmount: rewardAmount,
                rewardCoinDecimals: CONFIG.coins["USDC"].decimals,
                rewardCoinSymbol: "USDC"
            });
        });

        it("if there is one user with liquidity, should allocate all rewards to that user", async () => {
            const positionId = await provideLiquidityToPool(
                pool,
                4545,
                5500,
                1,
                5000,
                true
            );

            // adding more liquidity to same position
            await provideLiquidityToPool(pool, 4545, 5500, 1, 5000);

            // sleep untill rewards end time
            const sleepTime =
                new Date(
                    rewardsStartTimeInSeconds * 1000 + rewardsActiveForSeconds * 1000
                ).getTime() - Date.now();
            if (sleepTime > 0) {
                console.log("[Test sleeping] : ", sleepTime / 1000, "s");
                await sleep(sleepTime);
            }

            const txResponse1 = (await ONCHAIN_CALLS.getAccrcuedRewards(pool, positionId, {
                rewardCoinsType: [
                    CONFIG.coins["USDC"].type
                ]
            }))[0];

            //user should get almost all rewards allocated as this user was the only one providing liquidity (allowing delta of 0.2 usdc)
            expect(+txResponse1.coinAmount).to.be.approximately(
                rewardAmount.toNumber(),
                200000
            );
        });

        it("if there are 2 users with equal liquidity, should allocate all rewards to both users equally", async () => {
            // User 1(Admin) providing liquidity
            const txResponse = await ONCHAIN_CALLS.openPosition(
                pool,
                priceToTick(pool, 4545),
                priceToTick(pool, 5500)
            );

            const positionID = (
                Transaction.getEvents(
                    txResponse,
                    "PositionOpened"
                )[0] as IPositionOpenEvent
            ).position_id;

            const coinAmounts = {
                coinA: new BN(toBigNumberStr(1, pool.coin_a.decimals)),
                coinB: new BN(toBigNumberStr(5000, pool.coin_b.decimals))
            };

            const liquidityParams = getLiquidityParams(pool, 4545, 5500, coinAmounts, 1);

            await ONCHAIN_CALLS.provideLiquidity(pool, positionID, liquidityParams, {
                dryRun: false
            });

            await ONCHAIN_CALLS.provideLiquidity(pool, positionID, liquidityParams, {
                dryRun: false
            });

            // User 2 Providing liquidity now
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            await provideCoins(
                "BLUE",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["BLUE"].decimals)
            );

            await provideCoins(
                "USDC",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["USDC"].decimals)
            );

            const USER_ONCHAIN_CALLS = new OnChainCalls(SUI_CLIENT, DEPLOYMENT, {
                signer: WALLET
            });

            const txResponse2 = await USER_ONCHAIN_CALLS.openPosition(
                pool,
                priceToTick(pool, 4545),
                priceToTick(pool, 5500)
            );

            const positionID2 = (
                Transaction.getEvents(
                    txResponse2,
                    "PositionOpened"
                )[0] as IPositionOpenEvent
            ).position_id;

            await USER_ONCHAIN_CALLS.provideLiquidity(
                pool,
                positionID2,
                liquidityParams,
                {
                    dryRun: false
                }
            );

            await USER_ONCHAIN_CALLS.provideLiquidity(
                pool,
                positionID2,
                liquidityParams,
                {
                    dryRun: false
                }
            );

            // sleep untill rewards end time
            const sleepTime =
                new Date(
                    rewardsStartTimeInSeconds * 1000 + rewardsActiveForSeconds * 1000
                ).getTime() - Date.now();
            if (sleepTime > 0) {
                console.log("[Test sleeping] : ", sleepTime / 1000, "s");
                await sleep(sleepTime);
            }

            const txResponse3 = (await ONCHAIN_CALLS.getAccrcuedRewards(pool, positionID, {
                rewardCoinsType: [
                    CONFIG.coins["USDC"].type
                ]
            }))[0];

            const txResponse4 = (await USER_ONCHAIN_CALLS.getAccrcuedRewards(
                pool,
                positionID2,
                { rewardCoinsType: [CONFIG.coins["USDC"].type] }
            ))[0];

            //user 1 should get half of all rewards allocated as this user was providing half liquidity (allowing delta of 0.1 usdc)
            expect(+txResponse3.coinAmount).to.be.approximately(
                rewardAmount.div(new BigNumber("2")).toNumber(),
                100000
            );
            //user 2 should also get half of all rewards allocated as this user was providing half liquidity (allowing delta of 0.1 usdc)
            expect(+txResponse4.coinAmount).to.be.approximately(
                rewardAmount.div(new BigNumber("2")).toNumber(),
                100000
            );
        });

        it("user should be able to collect the accrued rewards", async () => {
            const positionId = await provideLiquidityToPool(
                pool,
                4545,
                5500,
                1,
                5000,
                true
            );

            // adding more liquidity to same position
            await provideLiquidityToPool(pool, 4545, 5500, 1, 5000);

            // sleep untill rewards end time
            const sleepTime =
                new Date(
                    rewardsStartTimeInSeconds * 1000 + rewardsActiveForSeconds * 1000
                ).getTime() - Date.now();
            if (sleepTime > 0) {
                console.log("[Test sleeping] : ", sleepTime / 1000, "s");
                await sleep(sleepTime);
            }

            const balanceBefore = (
                await ONCHAIN_CALLS.suiClient.getBalance({
                    owner: ONCHAIN_CALLS.signerConfig.address,
                    coinType: CONFIG.coins["USDC"].type
                })
            ).totalBalance;

            await ONCHAIN_CALLS.collectRewards(pool, positionId, {
                rewardCoinsType: [
                    CONFIG.coins["USDC"].type
                ]
            });

            const balanceAfter = (
                await ONCHAIN_CALLS.suiClient.getBalance({
                    owner: ONCHAIN_CALLS.signerConfig.address,
                    coinType: CONFIG.coins["USDC"].type
                })
            ).totalBalance;

            // Balance after collecting rewards should update
            expect(+balanceAfter).to.be.approximately(
                +balanceBefore + rewardAmount.toNumber(),
                200000
            );
        });
    });

    describe("After initializing BLUE rewards, When adding liquidity in pool: ", () => {
        let rewardsStartTimeInSeconds;
        let rewardsActiveForSeconds;
        const rewardAmount = new BigNumber("10000000000"); // 10 BLUE
        beforeEach(async () => {
            rewardsStartTimeInSeconds = Math.floor(Date.now() / 1000) + 60; // 60 seconds seconds in future
            rewardsActiveForSeconds = 40; // available for 40 seconds

            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            const rewardsManager = WALLET.toSuiAddress();

            await ONCHAIN_CALLS.addRewardsManager(rewardsManager);

            await provideCoins(
                "BLUE",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["BLUE"].decimals)
            );

            const REWARD_MANAGER_ONCHAIN_CALLS = new OnChainCalls(
                SUI_CLIENT,
                DEPLOYMENT,
                {
                    signer: WALLET
                }
            );

            await REWARD_MANAGER_ONCHAIN_CALLS.addRewardCoinInPool({
                pool,
                startTime: rewardsStartTimeInSeconds,
                activeForSeconds: rewardsActiveForSeconds,
                rewardCoinType: CONFIG.coins["BLUE"].type,
                rewardCoinAmount: new BigNumber("0"),
                rewardCoinDecimals: CONFIG.coins["BLUE"].decimals,
                rewardCoinSymbol: "BLUE",
                blueRewardAmount: rewardAmount
            });
        });

        it("if there is one user with liquidity, should allocate almost half rewards to that user at half time past in rewards emission", async () => {
            const positionId = await provideLiquidityToPool(
                pool,
                4545,
                5500,
                1,
                5000,
                true
            );

            // adding more liquidity to same position
            await provideLiquidityToPool(pool, 4545, 5500, 1, 5000);

            // sleep untill half the time since start of rewards emission
            const sleepTime =
                new Date(
                    rewardsStartTimeInSeconds * 1000 +
                    (rewardsActiveForSeconds / 2) * 1000
                ).getTime() - Date.now();
            if (sleepTime > 0) {
                console.log("[Test sleeping] : ", sleepTime / 1000, "s");
                await sleep(sleepTime);
            }

            const txResponse1 = (await ONCHAIN_CALLS.getAccrcuedRewards(pool, positionId, {
                rewardCoinsType: [
                    CONFIG.coins["BLUE"].type
                ]
            }))[0];

            // user should get almost half of all rewards allocated as this user was the only one providing liquidity (allowing delta of 1 Blue)
            expect(+txResponse1.coinAmount).to.be.approximately(
                rewardAmount.toNumber() / 2,
                1000000000
            );
        });

        it("if there are 2 users with equal liquidity, should allocate all rewards to both users equally", async () => {
            // User 1(Admin) providing liquidity
            const txResponse = await ONCHAIN_CALLS.openPosition(
                pool,
                priceToTick(pool, 4545),
                priceToTick(pool, 5500)
            );

            const positionID = (
                Transaction.getEvents(
                    txResponse,
                    "PositionOpened"
                )[0] as IPositionOpenEvent
            ).position_id;

            const coinAmounts = {
                coinA: new BN(toBigNumberStr(1, pool.coin_a.decimals)),
                coinB: new BN(toBigNumberStr(5000, pool.coin_b.decimals))
            };

            const liquidityParams = getLiquidityParams(pool, 4545, 5500, coinAmounts, 1);

            await ONCHAIN_CALLS.provideLiquidity(pool, positionID, liquidityParams, {
                dryRun: false
            });

            await ONCHAIN_CALLS.provideLiquidity(pool, positionID, liquidityParams, {
                dryRun: false
            });

            // User 2 Providing liquidity now
            const WALLET = getKeyPairFromPvtKey(
                "0x9e36456bda63e8fb4f33cd40ca6fa0afc14dbdd58de1071eb52b77a7231fb789",
                "Secp256k1"
            );

            await provideCoins(
                "BLUE",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["BLUE"].decimals)
            );

            await provideCoins(
                "USDC",
                WALLET.toSuiAddress(),
                toBigNumber(10_000, CONFIG.coins["USDC"].decimals)
            );

            const USER_ONCHAIN_CALLS = new OnChainCalls(SUI_CLIENT, DEPLOYMENT, {
                signer: WALLET
            });

            const txResponse2 = await USER_ONCHAIN_CALLS.openPosition(
                pool,
                priceToTick(pool, 4545),
                priceToTick(pool, 5500)
            );

            const positionID2 = (
                Transaction.getEvents(
                    txResponse2,
                    "PositionOpened"
                )[0] as IPositionOpenEvent
            ).position_id;

            await USER_ONCHAIN_CALLS.provideLiquidity(
                pool,
                positionID2,
                liquidityParams,
                {
                    dryRun: false
                }
            );

            await USER_ONCHAIN_CALLS.provideLiquidity(
                pool,
                positionID2,
                liquidityParams,
                {
                    dryRun: false
                }
            );

            // sleep untill rewards end time
            const sleepTime =
                new Date(
                    rewardsStartTimeInSeconds * 1000 +
                    (rewardsActiveForSeconds / 2) * 1000
                ).getTime() - Date.now();
            if (sleepTime > 0) {
                console.log("[Test sleeping] : ", sleepTime / 1000, "s");
                await sleep(sleepTime);
            }

            const txResponse3 = (await ONCHAIN_CALLS.getAccrcuedRewards(pool, positionID, {
                rewardCoinsType: [
                    CONFIG.coins["BLUE"].type
                ]
            }))[0];

            const txResponse4 = (await USER_ONCHAIN_CALLS.getAccrcuedRewards(
                pool,
                positionID2,
                { rewardCoinsType: [CONFIG.coins["BLUE"].type] }
            ))[0];

            const expectedRewardsAllocatedUntillHalfTime = rewardAmount
                .div(new BigNumber("2"))
                .toNumber();

            //user 1 should get half of expected rewards allocated  as this user was providing half liquidity (allowing delta of 0.5 Blue)
            expect(+txResponse3.coinAmount).to.be.approximately(
                expectedRewardsAllocatedUntillHalfTime / 2,
                500000000
            );
            //user 2 should also get half of all rewards allocated as this user was providing half liquidity (allowing delta of 0.5 Blue)
            expect(+txResponse4.coinAmount).to.be.approximately(
                expectedRewardsAllocatedUntillHalfTime / 2,
                500000000
            );
        });

        it("user should be able to collect the accrued rewards", async () => {
            const positionId = await provideLiquidityToPool(
                pool,
                4545,
                5500,
                1,
                5000,
                true
            );

            // adding more liquidity to same position
            await provideLiquidityToPool(pool, 4545, 5500, 1, 5000);

            // sleep untill rewards end time
            const sleepTime =
                new Date(
                    rewardsStartTimeInSeconds * 1000 + rewardsActiveForSeconds * 1000
                ).getTime() - Date.now();
            if (sleepTime > 0) {
                console.log("[Test sleeping] : ", sleepTime / 1000, "s");
                await sleep(sleepTime);
            }

            const balanceBefore = (
                await ONCHAIN_CALLS.suiClient.getBalance({
                    owner: ONCHAIN_CALLS.signerConfig.address,
                    coinType: CONFIG.coins["BLUE"].type
                })
            ).totalBalance;

            const txResponse = await ONCHAIN_CALLS.collectRewards(pool, positionId, {
                rewardCoinsType: [
                    CONFIG.coins["BLUE"].type
                ]
            });

            const userRewards = Transaction.getEvents(
                txResponse,
                "UserRewardCollected"
            )[0] as IUserRewardClaimedEvent;

            const balanceAfter = (
                await ONCHAIN_CALLS.suiClient.getBalance({
                    owner: ONCHAIN_CALLS.signerConfig.address,
                    coinType: CONFIG.coins["BLUE"].type
                })
            ).totalBalance;

            // Balance after collecting rewards should be equal , as blue coins are not transfered at the moment
            expect(+balanceAfter).to.be.approximately(+balanceBefore, 200000000);

            expect(+userRewards.reward_amount).to.be.approximately(
                rewardAmount.toNumber(),
                200000000
            );
        });
    });
});
