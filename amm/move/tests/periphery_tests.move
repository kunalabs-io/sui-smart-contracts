#[test_only]
module 0x0::periphery_tests {
    use 0x0::periphery;
    use sui::test_scenario as ts;
    use sui::coin::{Self, Coin};

    const USER: address = @0xB0B;

    struct TEST_COIN has drop {}

    #[test]
    fun test_maybe_split_and_transfer_doesnt_split_on_exact_amount() {
        let scenario = ts::begin(USER);
        {
            let ctx = ts::ctx(&mut scenario);
            let input = coin::mint_for_testing<TEST_COIN>(100, ctx);
            let out = periphery::maybe_split_and_transfer_rest(input, 100, USER, ctx);

            assert!(coin::value(&out) == 100, 0);
            coin::destroy_for_testing(out);
        };

        ts::next_tx(&mut scenario, USER);
        {
            assert!(ts::has_most_recent_for_sender<Coin<TEST_COIN>>(&scenario) == false, 0);
        };

        ts::end(scenario);
    }

    #[test]
    fun test_maybe_split_and_transfer_splits_when_input_larger() {
        let scenario = ts::begin(USER);
        {
            let ctx = ts::ctx(&mut scenario);
            let input = coin::mint_for_testing<TEST_COIN>(150, ctx);
            let out = periphery::maybe_split_and_transfer_rest(input, 100, USER, ctx);

            assert!(coin::value(&out) == 100, 0);
            coin::destroy_for_testing(out);
        };

        ts::next_tx(&mut scenario, USER);
        {
            let rest = ts::take_from_sender<Coin<TEST_COIN>>(&mut scenario);
            assert!(coin::value(&rest) == 50, 0);
            coin::destroy_for_testing(rest);
        };

        ts::end(scenario);
    }
}