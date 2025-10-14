import { CONFIG, ONCHAIN_CALLS } from "../env";
import { Transaction } from "../library-sui/src/classes/Transaction";
import { expect } from "./helpers/utils";

describe("Pool", () => {

    it("should create a BLUE/USDC pool", async ()=> {

        console.log(CONFIG.coins["BLUE"]);
        console.log(CONFIG.coins["USDC"]);

        const resp = await ONCHAIN_CALLS.createPool (
            CONFIG.coins["BLUE"],
            CONFIG.coins["USDC"],
            `BLUE/USDC`,
            1, // tick spacing
            1, // 1 bps fee
            5000, // starting price
            { dryRun: true }
        );
        
        expect(Transaction.getStatus(resp)).to.be.equal("success");

        const event = Transaction.getEvents(resp, "PooCreated")[0];
        expect(event.current_tick_index.bits).to.be.equal(16095);

    });

});