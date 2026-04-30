import { sleep } from "../../library-sui/src";
import { deploy, genesis } from "../../scripts/";

async function main() {
    await deploy();
    await sleep(1000);
    await genesis();
}

main();
