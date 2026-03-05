module x::witness {

    use sui::package;
    use x::witness;

    struct WitnessGenerator<phantom T0> has store {
        dummy_field: bool,
    }
    struct Witness<phantom T0> has drop {
        dummy_field: bool,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun from_publisher<T0>(a0: &package::Publisher): witness::Witness<T0>;
 #[native_interface]
    native public fun to_generator<T0>(a0: witness::Witness<T0>): witness::WitnessGenerator<T0>;
 #[native_interface]
    native public fun from_generator<T0>(a0: witness::WitnessGenerator<T0>): witness::Witness<T0>;
 #[native_interface]
    native public fun assert_publisher<T0>(a0: &package::Publisher);

}
