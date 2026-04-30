axiom (forall x: int :: {$xorInt'u8'(x, $MAX_U8)}
    $xorInt'u8'(x, $MAX_U8) == $MAX_U8 - x
);

axiom (forall x: int :: {$xorInt'u32'(x, $MAX_U32)}
    $xorInt'u32'(x, $MAX_U32) == $MAX_U32 - x
);

axiom (forall x: int :: {$xorInt'u64'(x, $MAX_U64)}
    $xorInt'u64'(x, $MAX_U64) == $MAX_U64 - x
);

axiom (forall x: int :: {$xorInt'u128'(x, $MAX_U128)}
    $xorInt'u128'(x, $MAX_U128) == $MAX_U128 - x
);

const $POW_TWO_31: int;
axiom $POW_TWO_31 == 2147483648;  // 2^31
axiom (forall x: int :: {$orInt'u32'(x, $POW_TWO_31)}
    $orInt'u32'(x, $POW_TWO_31) == if x < $POW_TWO_31 then x + $POW_TWO_31 else x
);

const $POW_TWO_63: int;
axiom $POW_TWO_63 == 9223372036854775808;  // 2^63
axiom (forall x: int :: {$orInt'u64'(x, $POW_TWO_63)}
    $orInt'u64'(x, $POW_TWO_63) == if x < $POW_TWO_63 then x + $POW_TWO_63 else x
);

const $TWO_POW_127: int;
axiom $TWO_POW_127 == 170141183460469231731687303715884105728;  // 2^127
axiom (forall x: int :: {$orInt'u128'(x, $TWO_POW_127)}
    $orInt'u128'(x, $TWO_POW_127) == if x < $TWO_POW_127 then x + $TWO_POW_127 else x
);

const $LO_64_MASK: int;
axiom $LO_64_MASK == 18446744073709551615;  // 2^64 - 1
const $HI_64_MASK: int;
axiom $HI_64_MASK == 340282366920938463444927863358058659840; // 2^128 - 2^64
const $TWO_POW_64: int;
axiom $TWO_POW_64 == 18446744073709551616;  // 2^64

axiom (forall x: int :: {$andInt'u128'(x, $LO_64_MASK)}
    $andInt'u128'(x, $LO_64_MASK) == x mod $TWO_POW_64
);

axiom (forall x: int :: {$andInt'u128'(x, $HI_64_MASK)}
    $andInt'u128'(x, $HI_64_MASK) == (x div $TWO_POW_64) * $TWO_POW_64
);

const $LO_128_MASK: int;
axiom $LO_128_MASK == 340282366920938463463374607431768211455;  // 2^128 - 1
const $HI_128_MASK: int;
axiom $HI_128_MASK == 115792089237316195423570985008687907852929702298719625575994209400481361428480;  // 2^256 - 2^128
const $TWO_POW_128: int;
axiom $TWO_POW_128 == 340282366920938463463374607431768211456;  // 2^128

axiom (forall x: int :: {$andInt'u256'(x, $LO_128_MASK)}
    $andInt'u256'(x, $LO_128_MASK) == x mod $TWO_POW_128
);

axiom (forall x: int :: {$andInt'u256'(x, $HI_128_MASK)}
    $andInt'u256'(x, $HI_128_MASK) == (x div $TWO_POW_128) * $TWO_POW_128
);

axiom (forall x: int :: {$shr(x, 127)}
    $shr(x, 127) == x div $TWO_POW_127
);

axiom (forall x: int :: {$shr(x, 128)}
    $shr(x, 128) == x div $TWO_POW_128
);

// Complete truth table for bitwise AND with 0, 1, 254 (complement of 1), 255 (complement of 0)
axiom ($andInt'u8'(0, 0) == 0);
axiom ($andInt'u8'(0, 1) == 0);
axiom ($andInt'u8'(0, 254) == 0);
axiom ($andInt'u8'(0, 255) == 0);
axiom ($andInt'u8'(1, 0) == 0);
axiom ($andInt'u8'(1, 1) == 1);
axiom ($andInt'u8'(1, 254) == 0);
axiom ($andInt'u8'(1, 255) == 1);
axiom ($andInt'u8'(254, 0) == 0);
axiom ($andInt'u8'(254, 1) == 0);
axiom ($andInt'u8'(254, 254) == 254);
axiom ($andInt'u8'(254, 255) == 254);
axiom ($andInt'u8'(255, 0) == 0);
axiom ($andInt'u8'(255, 1) == 1);
axiom ($andInt'u8'(255, 254) == 254);
axiom ($andInt'u8'(255, 255) == 255);

