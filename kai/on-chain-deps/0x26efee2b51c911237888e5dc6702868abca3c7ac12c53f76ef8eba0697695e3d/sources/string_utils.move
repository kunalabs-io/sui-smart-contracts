module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::string_utils {

    use 0x1::ascii;
    use 0x1::string;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun to_ascii(a0: &string::String): ascii::String;

}
