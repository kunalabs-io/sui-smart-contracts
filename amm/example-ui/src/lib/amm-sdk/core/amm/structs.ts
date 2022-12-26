import {
  getMoveObject,
  getObjectExistsResponse,
  ObjectId,
  Provider,
  StructTag,
  SuiMoveObject,
  SuiObject,
  TypeTag,
} from '@mysten/sui.js'
import { PACKAGE_ID } from '..'
import { Balance, Supply } from '../../framework/balance'
import { tagToType, Type, typeToTag } from '../type'
import { bcs } from './bcs'

export class LP {
  readonly typeArgs: [Type, Type]

  constructor(typeArgs: [Type, Type]) {
    this.typeArgs = typeArgs
  }

  static isLp(type: Type): boolean {
    return type.startsWith(`${PACKAGE_ID}::amm::LP<`)
  }

  static parseTypeArgs(type: Type): [Type, Type] {
    if (!this.isLp(type)) {
      throw new Error(`Not a LP type: ${type}`)
    }
    const tag = typeToTag(type)
    if (!('struct' in tag)) {
      throw new Error(`Not a StructTag`)
    }
    return [tagToType(tag.struct.typeParams[0]), tagToType(tag.struct.typeParams[1])]
  }
}

export class PoolCreationEvent {
  readonly poolId: ObjectId

  constructor(poolId: ObjectId) {
    this.poolId = poolId
  }

  static fromBcs(data: Uint8Array | string, encoding?: string) {
    const dec = bcs.de(`${PACKAGE_ID}::amm::PoolCreationEvent`, data, encoding)
    return new PoolCreationEvent(dec.pool_id)
  }

  static isPoolCreationEvent(type: Type): boolean {
    return type.startsWith(`${PACKAGE_ID}::amm::PoolCreationEvent<`)
  }
}

export interface PoolFields {
  id: ObjectId
  balanceA: Balance
  balanceB: Balance
  lpSupply: Supply
  lpFeeBps: bigint
  adminFeePct: bigint
  adminFeeBalance: Balance
}

export class Pool implements PoolFields {
  readonly typeArgs: [Type, Type]

  readonly id: ObjectId
  readonly balanceA: Balance
  readonly balanceB: Balance
  readonly lpSupply: Supply
  readonly lpFeeBps: bigint
  readonly adminFeePct: bigint
  readonly adminFeeBalance: Balance

  constructor(typeArgs: [Type, Type], fields: PoolFields) {
    this.typeArgs = typeArgs
    this.id = fields.id
    this.balanceA = fields.balanceA
    this.balanceB = fields.balanceB
    this.lpSupply = fields.lpSupply
    this.lpFeeBps = fields.lpFeeBps
    this.adminFeePct = fields.adminFeePct
    this.adminFeeBalance = fields.adminFeeBalance
  }

  static isPool(type: Type): boolean {
    return type.startsWith(`${PACKAGE_ID}::amm::Pool<`)
  }

  static fromSuiObject(obj: SuiObject): Pool {
    const id = obj.reference.objectId
    const moveObj = getMoveObject(obj)
    if (moveObj === undefined) {
      throw new Error(`'${id}' is not a valid Pool object`)
    }
    return this.fromMoveObjectField(moveObj)
  }

  static fromMoveObjectField(field: SuiMoveObject): Pool {
    if (!Pool.isPool(field.type)) {
      throw new Error(`not a Pool type`)
    }

    const struct = (typeToTag(field.type) as { struct: StructTag }).struct
    const [typeA, typeB] = (struct.typeParams as [TypeTag, TypeTag]).map(tagToType)

    return {
      typeArgs: [typeA, typeB],
      id: field.fields.id.id,
      balanceA: Balance.fromMoveObjectField(typeA, field.fields.balance_a),
      balanceB: Balance.fromMoveObjectField(typeB, field.fields.balance_b),
      lpSupply: Supply.fromMoveObjectField(field.fields.lp_supply),
      lpFeeBps: BigInt(field.fields.lp_fee_bps),
      adminFeePct: BigInt(field.fields.admin_fee_pct),
      adminFeeBalance: Balance.fromMoveObjectField(typeB, field.fields.admin_fee_balance),
    }
  }

  static async fetch(provider: Provider, id: ObjectId): Promise<Pool> {
    const res = await provider.getObject(id)
    const obj = getObjectExistsResponse(res)
    if (obj == undefined) {
      throw new Error('object does not exist')
    }
    return this.fromSuiObject(obj)
  }
}
