/// Deploys the package using the deployer private key provided in .env
/// Transfers package upgrade cap to the deployer
/// Writes the deployment details to deployment.json
import path from "path";
import { execSync } from "child_process";

import { ADMIN, ENV, ONCHAIN_CALLS } from "../env";
import { TransactionBlock } from "../library-sui";
import {
    readJSONFile,
    getCreatedObjectsIDs,
    writeJSONFile,
    sleep
} from "../library-sui/src/blv";

export async function deploy() {
    const deployerAddress = ADMIN.getPublicKey().toSuiAddress();
    console.log(`Deployer: ${deployerAddress}`);
    
    const pkgPath = path.join(path.resolve(__dirname), "../");

    const { modules, dependencies } = JSON.parse(
        execSync(`sui move build --dump-bytecode-as-base64 --path ${pkgPath}`, {
            encoding: "utf-8"
        })
    );

    const tx = new TransactionBlock();

    const [upgradeCap] = tx.publish({ modules, dependencies });

    tx.transferObjects([upgradeCap], tx.pure.address(deployerAddress));

    console.log("Deploying");
    await sleep(3000);
    const result = await ONCHAIN_CALLS.signAndExecuteTxBlock(tx);

    await sleep(3000);

    const objects = getCreatedObjectsIDs(result);

    const filePath = "./deployment.json";
    const deployment = readJSONFile(filePath);
    
    objects["BasePackage"] = objects["Package"];
    objects["CurrentPackage"] = objects["Package"];
    delete objects["Package"];

    deployment[ENV.DEPLOY_ON] = {
        ...objects,
        Operators: { Admin: deployerAddress, ProtocolFeeHandler: deployerAddress },
    };

    writeJSONFile(filePath, deployment);

    // log objects
    console.log(`Object ids saved to: ${filePath}`);
    console.dir(objects, null);
}

if (require.main === module) {
    deploy();
}
