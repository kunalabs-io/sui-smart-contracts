/// Builds the move package using sui cli

import { execSync } from "child_process";
import path from "path";
async function main() {
    const pkgPath = path.join(path.resolve(__dirname), "../");
    execSync(`sui move build --dump-bytecode-as-base64 --path ${pkgPath}`, {
        encoding: "utf-8"
    });
}

main();
