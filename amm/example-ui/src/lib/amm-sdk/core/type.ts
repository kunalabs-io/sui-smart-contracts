import { TypeTag } from '@mysten/sui.js'

export type Type = string

export function tagToType(tag: TypeTag): Type {
  return toString(tag)
}

export function typeToTag(type: Type): TypeTag {
  return parseFromStr(type)
}

export function isTypeTagEqual(tag1: TypeTag, tag2: TypeTag): boolean {
  if ('vector' in tag1 && 'vector' in tag2) {
    isTypeTagEqual(tag1.vector, tag2.vector)
  }
  if ('struct' in tag1 && 'struct' in tag2) {
    const [s1, s2] = [tag1.struct, tag2.struct]
    if (s1.address !== s2.address) {
      return false
    }
    if (s1.module !== s2.module) {
      return false
    }
    if (s1.name !== s2.name) {
      return false
    }
    if (s1.typeParams.length !== s2.typeParams.length) {
      return false
    }
    for (let i = 0; i < s1.typeParams.length; i++) {
      if (isTypeTagEqual(s1.typeParams[i], s2.typeParams[i]) === false) {
        return false
      }
    }
    return true
  }
  if (Object.keys(tag1)[0] === Object.keys(tag1)[0]) {
    return true
  }
  return false
}

const VECTOR_REGEX = /^vector<(.+)>$/
const STRUCT_REGEX = /^([^:]+)::([^:]+)::([^<]+)(<(.+)>)?/

function parseFromStr(str: string): TypeTag {
  if (str === 'address') {
    return { address: null }
  } else if (str === 'bool') {
    return { bool: null }
  } else if (str === 'u8') {
    return { u8: null }
  } else if (str === 'u16') {
    return { u16: null }
  } else if (str === 'u32') {
    return { u32: null }
  } else if (str === 'u64') {
    return { u64: null }
  } else if (str === 'u128') {
    return { u128: null }
  } else if (str === 'u256') {
    return { u256: null }
  } else if (str === 'signer') {
    return { signer: null }
  }
  const vectorMatch = str.match(VECTOR_REGEX)
  if (vectorMatch) {
    return { vector: parseFromStr(vectorMatch[1]) }
  }

  const structMatch = str.match(STRUCT_REGEX)
  if (structMatch) {
    return {
      struct: {
        address: structMatch[1],
        module: structMatch[2],
        name: structMatch[3],
        typeParams: structMatch[5] === undefined ? [] : parseStructTypeArgs(structMatch[5]),
      },
    }
  }

  throw new Error(`Encounter unexpected token when parsing type args for ${str}`)
}

function parseStructTypeArgs(str: string): TypeTag[] {
  // split `str` by all `,` outside angle brackets
  const tok: Array<string> = []
  let word = ''
  let nestedAngleBrackets = 0
  for (let i = 0; i < str.length; i++) {
    const char = str[i]
    if (char === '<') {
      nestedAngleBrackets++
    }
    if (char === '>') {
      nestedAngleBrackets--
    }
    if (nestedAngleBrackets == 0 && char === ',') {
      tok.push(word.trim())
      word = ''
      continue
    }
    word += char
  }

  tok.push(word.trim())

  return tok.map(parseFromStr)
}

function toString(type: TypeTag): string {
  if ('bool' in type) {
    return 'bool'
  }
  if ('u8' in type) {
    return 'u8'
  }
  if ('u16' in type) {
    return 'u16'
  }
  if ('u32' in type) {
    return 'u32'
  }
  if ('u64' in type) {
    return 'u64'
  }
  if ('u128' in type) {
    return 'u128'
  }
  if ('u256' in type) {
    return 'u256'
  }
  if ('address' in type) {
    return 'address'
  }
  if ('signer' in type) {
    return 'signer'
  }
  if ('vector' in type) {
    return `vector<${toString(type.vector)}>`
  }
  if ('struct' in type) {
    const struct = type.struct
    const typeParams = struct.typeParams.map(toString).join(', ')
    return `${struct.address}::${struct.module}::${struct.name}${
      typeParams ? `<${typeParams}>` : ''
    }`
  }
  throw new Error('Invalid type tag')
}
