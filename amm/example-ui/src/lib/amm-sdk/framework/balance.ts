import { StructTag, SuiMoveObject } from '@mysten/sui.js'
import { tagToType, Type, typeToTag } from '../core/type'

export class Balance {
  constructor(readonly typeArg: Type, readonly value: bigint) {}

  static fromMoveObjectField(type: Type, field: string): Balance {
    return new Balance(type, BigInt(field))
  }
}

export class Supply {
  constructor(readonly typeArg: Type, readonly value: bigint) {}

  static fromMoveObjectField(field: SuiMoveObject): Supply {
    if (!field.type.startsWith('0x2::balance::Supply<')) {
      throw new Error('error parsing Supply')
    }
    const type = typeToTag(field.type) as {
      struct: StructTag
    }
    return new Supply(tagToType(type.struct.typeParams[0]), BigInt(field.fields.value))
  }
}
