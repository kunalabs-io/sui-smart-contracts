/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::i128H  {

    use integer_mate::i128::{Self as MateI128, I128 as MateI128Type};
    use integer_library::i128::{Self as LibraryI128, I128 as LibraryI128Type};
    use bluefin_spot::errors;

    public fun mate_to_lib(num: MateI128Type) : LibraryI128Type {  
       LibraryI128::from_u128(
            MateI128::as_u128(num)
        )
    }

    public fun lib_to_mate(num: LibraryI128Type) : MateI128Type {  
        let value = LibraryI128::abs_u128(num);
        if (LibraryI128::is_neg(num)) {
            MateI128::neg_from(value)
        } else {
            MateI128::from(value)
        }
    }

    public fun sub(a: MateI128Type, b: MateI128Type) : MateI128Type {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        lib_to_mate(LibraryI128::sub(a_lib, b_lib))
    }

    public fun add(a: MateI128Type, b: MateI128Type) : MateI128Type {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        lib_to_mate(LibraryI128::add(a_lib, b_lib))
    }

public fun eq(a: MateI128Type, b: MateI128Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI128::eq(a_lib, b_lib)
    }

    public fun lt(a: MateI128Type, b: MateI128Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI128::lt(a_lib, b_lib)
    }

    public fun gt(a: MateI128Type, b: MateI128Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI128::gt(a_lib, b_lib)
    }

    public fun lte(a: MateI128Type, b: MateI128Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI128::lte(a_lib, b_lib)
    }

    public fun gte(a: MateI128Type, b: MateI128Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI128::gte(a_lib, b_lib)
    }

    public fun is_neg(num: MateI128Type) : bool {
        LibraryI128::is_neg(mate_to_lib(num))
    }

    public fun neg_from(_: MateI128Type) : MateI128Type {
        abort errors::depricated()
    }

    public fun neg(num: MateI128Type) : MateI128Type {
        lib_to_mate(LibraryI128::neg(mate_to_lib(num)))
    }



}