procedure {:inline 1} $0_i32_ashr($t0: bv32, $t1: bv32) returns ($ret0: bv32) {
  $ret0 := $AShr'Bv32'($t0, $t1);
}

procedure {:inline 1} $0_i64_ashr($t0: bv64, $t1: bv64) returns ($ret0: bv64) {
  $ret0 := $AShr'Bv64'($t0, $t1);
}

procedure {:inline 1} $0_i128_ashr($t0: bv128, $t1: bv128) returns ($ret0: bv128) {
  $ret0 := $AShr'Bv128'($t0, $t1);
}

