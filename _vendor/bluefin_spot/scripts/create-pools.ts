import { CONFIG, DEPLOYMENT, ENV, SUI_CLIENT } from "../env";
import { getKeyPairFromPvtKey, getKeyPairFromSeed, Transaction } from "../library-sui";
import { readJSONFile, writeJSONFile } from "../library-sui/src";
import { IPoolCreatedEvent } from "../library-sui/src/spot";
import { OnChainCalls } from "../library-sui/src/spot/on-chain-calls";

import dotenv from "dotenv";
dotenv.config();

async function main() {
    /** DO NOT PUSH THIS TO GIT */
    const admin =
        ENV.DEPLOYER_KEY != "0x"
            ? getKeyPairFromPvtKey(ENV.DEPLOYER_KEY, ENV.WALLET_SCHEME)
            : getKeyPairFromSeed(ENV.DEPLOYER_PHRASE, ENV.WALLET_SCHEME);
    const onChainCalls = new OnChainCalls(SUI_CLIENT, DEPLOYMENT, { signer: admin });

    const filePath = "./deployment.json";
    const deployment = readJSONFile(filePath);

    /** CONFIG */
    const coinA = "stSUI";
    const coinB = "mUSD";
    const dryRun = false;

    const fee = 5;
    const tickSpacing = 5;
    const startingPrice = 5.0;
    /** CONFIG */

    const gif = `https://bluefin.io/images/nfts/${coinA}-${coinB}.gif`;
    console.log(gif);

    const poolName = `${coinA}-${coinB}`;

    const response = await onChainCalls.createPool(
        CONFIG.coins[coinA],
        CONFIG.coins[coinB],
        poolName,
        tickSpacing,
        fee,
        startingPrice,
        CONFIG.coins["SUI"].type,
        { dryRun, iconURl: gif }
    );

    const event = Transaction.getEvents(response, "PoolCreated")[0] as IPoolCreatedEvent;

    const poolInfo = {
        id: event.id,
        coinA: `0x${event.coin_a}`,
        coinB: `0x${event.coin_b}`,
        coinADecimals: event.coin_a_decimals,
        coinBDecimals: event.coin_b_decimals,
        name: poolName,
        tickSpacing,
        fee: Number(event.fee_rate)
    };

    console.log(JSON.stringify(poolInfo));

    if (!dryRun) {
        deployment[ENV.DEPLOY_ON]["Pools"].push(poolInfo);
        writeJSONFile(filePath, deployment);
    }
}

main();
