/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::i64H {

    use integer_mate::i64::{Self as MateI64, I64 as MateI64Type};
    use integer_library::i64::{Self as LibraryI64, I64 as LibraryI64Type};


    public fun mate_to_lib(num: MateI64Type) : LibraryI64Type {  
       LibraryI64::from_u64(
            MateI64::as_u64(num)
        )
    }

    public fun lib_to_mate(num: LibraryI64Type) : MateI64Type {  
       MateI64::from_u64(
            LibraryI64::as_u64(num)
        )
    }

    public fun sub(a: MateI64Type, b: MateI64Type) : MateI64Type {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        lib_to_mate(LibraryI64::sub(a_lib, b_lib))
    }

    public fun add(a: MateI64Type, b: MateI64Type) : MateI64Type {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        lib_to_mate(LibraryI64::add(a_lib, b_lib))
    }

    public fun eq(a: MateI64Type, b: MateI64Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI64::eq(a_lib, b_lib)
    }

    public fun lt(a: MateI64Type, b: MateI64Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI64::lt(a_lib, b_lib)
    }

    public fun gt(a: MateI64Type, b: MateI64Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI64::gt(a_lib, b_lib)
    }

    public fun lte(a: MateI64Type, b: MateI64Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI64::lte(a_lib, b_lib)
    }

    public fun gte(a: MateI64Type, b: MateI64Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI64::gte(a_lib, b_lib)
    }

    public fun is_neg(num: MateI64Type) : bool {
        LibraryI64::is_neg(mate_to_lib(num))
    }

}