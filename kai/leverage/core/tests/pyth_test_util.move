#[test_only]
module kai_leverage::pyth_test_util;

use pyth::i64::{Self, I64};
use pyth::price;
use pyth::price_feed;
use pyth::price_identifier;
use pyth::price_info::{Self, PriceInfoObject};
use sui::bcs;
use sui::clock::Clock;

public fun create_pyth_pio(price: I64, clock: &Clock, ctx: &mut TxContext): PriceInfoObject {
    let timestamp_sec = clock.timestamp_ms() / 1000;

    let identifier = price_identifier::from_byte_vec(
        bcs::to_bytes(&tx_context::fresh_object_address(ctx)),
    );
    let price = price::new(
        price,
        0, // conf
        i64::new(8, true), // expo
        timestamp_sec,
    );
    let price_feed = price_feed::new(identifier, price, price);
    let price_info = price_info::new_price_info(
        timestamp_sec,
        timestamp_sec,
        price_feed,
    );
    price_info::new_price_info_object_for_testing(price_info, ctx)
}

public fun create_pyth_pio_with_price_human_mul_100(
    price_human_mul_100: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): PriceInfoObject {
    create_pyth_pio(i64::new(price_human_mul_100 * 10_u64.pow(6), false), clock, ctx)
}

public fun update_pyth_pio_price(pio: &mut PriceInfoObject, price: I64, clock: &Clock) {
    let timestamp_sec = clock.timestamp_ms() / 1000;

    let price_identifier = pio
        .get_price_info_from_price_info_object()
        .get_price_feed()
        .get_price_identifier();
    let price = price::new(
        price,
        0, // conf
        i64::new(8, true), // expo
        timestamp_sec,
    );
    let price_feed = price_feed::new(price_identifier, price, price);
    let price_info = price_info::new_price_info(
        timestamp_sec,
        timestamp_sec,
        price_feed,
    );

    pio.update_price_info_object_for_testing(price_info);
}

public fun update_pyth_pio_price_human_mul_n(
    pio: &mut PriceInfoObject,
    price_human_mul_n: u64,
    n: u8,
    clock: &Clock,
) {
    let price = if (n > 8) {
        price_human_mul_n / 10_u64.pow(n - 8)
    } else {
        price_human_mul_n * 10_u64.pow(8 - n)
    };

    update_pyth_pio_price(pio, i64::new(price, false), clock);
}

public fun set_pyth_pio_timestamp(pio: &mut PriceInfoObject, timestamp_sec: u64) {
    let price_identifier = pio
        .get_price_info_from_price_info_object()
        .get_price_feed()
        .get_price_identifier();
    let price_feed = pio.get_price_info_from_price_info_object().get_price_feed();

    let price = price_feed.get_price();
    let price = price::new(
        price.get_price(),
        price.get_conf(),
        price.get_expo(),
        timestamp_sec,
    );
    let price_feed = price_feed::new(price_identifier, price, price);
    let price_info = price_info::new_price_info(
        timestamp_sec,
        timestamp_sec,
        price_feed,
    );

    pio.update_price_info_object_for_testing(price_info);
}
