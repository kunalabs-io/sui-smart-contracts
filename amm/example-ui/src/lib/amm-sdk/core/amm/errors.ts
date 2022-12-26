export class EExcessiveSlippage extends Error {
  readonly code = 0
  readonly name = 'EExcessiveSlippage'
  readonly description = 'The pool balance differs from the acceptable.'
}

export class EZeroInput extends Error {
  readonly code = 1
  readonly name = 'EZeroInput'
  readonly description = 'The input amount is zero.'
}

export class EInvalidPoolID extends Error {
  readonly code = 2
  readonly name = 'EInvalidPoolID'
  readonly description = "The pool ID doesn't match the required."
}

export class ENoLiquidity extends Error {
  readonly code = 3
  readonly name = 'ENoLiquidity'
  readonly description = "There's no liquidity in the pool."
}

export class EInvalidFeeParam extends Error {
  readonly code = 4
  readonly name = 'EInvalidFeeParam'
  readonly description = 'Fee parameter is not valid.'
}

export class EInvalidAdminCap extends Error {
  readonly code = 5
  readonly name = 'EInvalidAdminCap'
  readonly description = "The provided admin capability doesn't belong to this pool"
}

export class EInvalidPair extends Error {
  readonly code = 6
  readonly name = 'EInvalidPair'
  readonly description =
    "Pool pair coin types must be ordered alphabetically (`A` < `B`) and mustn't be equal"
}

export class EPoolAlreadyExists extends Error {
  readonly code = 7
  readonly name = 'EPoolAlreadyExists'
  readonly description = 'Pool for this pair already exists'
}
