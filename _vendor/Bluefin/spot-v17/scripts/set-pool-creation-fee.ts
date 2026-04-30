import { CONFIG, ONCHAIN_CALLS } from "../env";
import { toBigNumberStr, Transaction } from "../library-sui";

async function main(){

    const coin = CONFIG.coins["USDC"];

    const { supported, amount } = await ONCHAIN_CALLS.getPoolCreationFeeInfoForCoin(coin.type);

    console.log({ supported, amount });

    const txResponse = await ONCHAIN_CALLS.setPoolCreationFee(
        coin.type,
        toBigNumberStr(20, coin.decimals),
        { dryRun: true }
    )

    const event = Transaction.getEvents(txResponse, "PoolCreationFeeUpdate")[0];

    console.dir(event);

}

main();