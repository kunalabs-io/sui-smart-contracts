import { config } from "dotenv";
import { SignatureScheme, SuiClient, getKeyPairFromPvtKey } from "./library-sui";
import { getKeyPairFromSeed } from "./library-sui";
import { readJSONFile } from "./library-sui/src/blv/utils";
import { DeployOn } from "./library-sui/src/blv/types";
import { IBluefinSpotContracts, IDeploymentConfig, QueryChain } from "./library-sui/src/spot";
import { OnChainCalls } from "./library-sui/src/spot/on-chain-calls";

config({ path: ".env" });

export const ENV = {
    DEPLOY_ON: process.env.DEPLOY_ON as DeployOn,
    DEPLOYER_KEY: process.env.DEPLOYER_KEY || "0x",
    DEPLOYER_PHRASE: process.env.DEPLOYER_PHRASE || "0x",
    // defaults wallet scheme to secp256k1
    WALLET_SCHEME: (process.env.WALLET_SCHEME || "Secp256k1") as SignatureScheme
};

export const CONFIG = readJSONFile("./config.json")[ENV.DEPLOY_ON] as IDeploymentConfig

export const DEPLOYMENT = readJSONFile("./deployment.json")[ENV.DEPLOY_ON] as IBluefinSpotContracts;

export const SUI_CLIENT = new SuiClient({
    url: CONFIG.rpc
});

export const ADMIN =
    ENV.DEPLOYER_KEY != "0x"
        ? getKeyPairFromPvtKey(ENV.DEPLOYER_KEY, ENV.WALLET_SCHEME)
        : getKeyPairFromSeed(ENV.DEPLOYER_PHRASE, ENV.WALLET_SCHEME);


export const ONCHAIN_CALLS = new OnChainCalls(SUI_CLIENT, DEPLOYMENT, {signer: ADMIN});

export const QUERY_CHAIN = new QueryChain(SUI_CLIENT);