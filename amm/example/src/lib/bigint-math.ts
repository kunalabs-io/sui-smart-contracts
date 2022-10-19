export function ceilDiv(a: bigint, b: bigint): bigint {
  return (a + (b - 1n)) / b
}

export function min(a: bigint, b: bigint): bigint {
  return a > b ? b : a
}

export function max(a: bigint, b: bigint): bigint {
  return a > b ? a : b
}
