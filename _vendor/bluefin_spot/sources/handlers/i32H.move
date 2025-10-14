/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::i32H {
    
    use integer_mate::i32::{Self as MateI32, I32 as MateI32Type};
    use integer_library::i32::{Self as LibraryI32, I32 as LibraryI32Type};


    public fun mate_to_lib(num: MateI32Type) : LibraryI32Type {  
       LibraryI32::from_u32(
            MateI32::as_u32(num)
        )
    }

    public fun lib_to_mate(num: LibraryI32Type) : MateI32Type {  
       MateI32::from_u32(
            LibraryI32::as_u32(num)
        )
    }

    public fun sub(a: MateI32Type, b: MateI32Type) : MateI32Type {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        lib_to_mate(LibraryI32::sub(a_lib, b_lib))
    }

    public fun add(a: MateI32Type, b: MateI32Type) : MateI32Type {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        lib_to_mate(LibraryI32::add(a_lib, b_lib))
    }

    public fun eq(a: MateI32Type, b: MateI32Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI32::eq(a_lib, b_lib)
    }

    public fun lt(a: MateI32Type, b: MateI32Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI32::lt(a_lib, b_lib)
    }

    public fun gt(a: MateI32Type, b: MateI32Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI32::gt(a_lib, b_lib)
    }

    public fun lte(a: MateI32Type, b: MateI32Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI32::lte(a_lib, b_lib)
    }

    public fun gte(a: MateI32Type, b: MateI32Type) : bool {
        let a_lib = mate_to_lib(a);
        let b_lib = mate_to_lib(b);
        LibraryI32::gte(a_lib, b_lib)
    }

    public fun is_neg(num: MateI32Type) : bool {
        LibraryI32::is_neg(mate_to_lib(num))
    }





}