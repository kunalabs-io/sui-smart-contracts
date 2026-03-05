module token_bridge::string_utils {

    use 0x1::ascii;
    use 0x1::string;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun to_ascii(a0: &string::String): ascii::String;

}
