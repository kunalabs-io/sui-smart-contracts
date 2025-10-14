/// Must be executed after deployment.
/// Performs the actions needed to be executed on genesis
/// of protocol like creating banks and other necessary objects
import { ADMIN, CONFIG, ENV, SUI_CLIENT } from "../env";
import { Transaction } from "../library-sui";
import { readJSONFile, writeJSONFile } from "../library-sui/src";
import { OnChainCalls } from "../library-sui/src/spot";
import { IPoolCreatedEvent } from "../library-sui/src/spot/interfaces/IChainEvents";

export async function genesis() {
    
    console.log("---> Performing Genesis Events <----");

    const filePath = "./deployment.json";
    const deployment = readJSONFile(filePath);

    const onChainCalls = new OnChainCalls(SUI_CLIENT, deployment[ENV.DEPLOY_ON], {signer: ADMIN});

    {
        console.log(`-> Creating BLUE/USDC pool`)
        const poolName = `BLUE-USDC`;
        const response = await onChainCalls.createPool(
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            poolName,
            1,
            1,
            0.15,
            CONFIG.coins["BLUE"].type,
            {dryRun: false}
        );

        const event = Transaction.getEvents(response, "PoolCreated")[0] as IPoolCreatedEvent;

        if(!deployment[ENV.DEPLOY_ON]["Pools"])
            deployment[ENV.DEPLOY_ON]["Pools"] = [];
        
        deployment[ENV.DEPLOY_ON]["Pools"].push(
            {
                id: event.id,
                coinA: `0x${event.coin_a}`,
                coinB: `0x${event.coin_b}`,
                coinADecimals: event.coin_a_decimals,
                coinBDecimals: event.coin_b_decimals,
                tickSpacing: event.tick_spacing,
                fee: event.fee_rate,
                name: poolName
            }
        )
    }

    writeJSONFile(filePath, deployment);
}

if (require.main === module) {
    genesis();
}
