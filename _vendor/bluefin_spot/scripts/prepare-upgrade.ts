

import path from "path";
import { execSync } from "child_process";
import { ADMIN, DEPLOYMENT, SUI_CLIENT } from "../env";
import { SuiBlocks, Transaction, TransactionBlock, UpgradePolicy } from "../library-sui";
import { toB64 } from "../library-sui";

async function prepareUpgrade(){

    const deployerAddress = ADMIN.getPublicKey().toSuiAddress();
    console.log(`Deployer: ${deployerAddress}`);
    
    const pkgPath = path.join(path.resolve(__dirname), "../");

    const { modules, dependencies, digest } = JSON.parse(
        execSync(`sui move build --dump-bytecode-as-base64 --path ${pkgPath}`, {
            encoding: "utf-8"
        })
    );

    const tx = new TransactionBlock();
    const cap = tx.object(DEPLOYMENT.UpgradeCap);

    const ticket = tx.moveCall({
        target: "0x2::package::authorize_upgrade",
        arguments: [cap, tx.pure.u8(UpgradePolicy.COMPATIBLE), tx.pure.vector('u8', digest)]
    });

    const receipt = tx.upgrade({
		modules,
		dependencies,
		package: DEPLOYMENT.CurrentPackage,
		ticket,
	});

   tx.moveCall({
       target: "0x2::package::commit_upgrade",
       arguments: [cap, receipt]
   });

    tx.setSender(deployerAddress);

    const txBytes = toB64(
        await tx.build({ client: SUI_CLIENT, onlyTransactionKind: false })
    );

    console.log(JSON.stringify({ txBytes }));
}

if (require.main === module) {
    prepareUpgrade();
}
