function isNumeric(value: string) {
  if (/^-?\d+(\.\d+)?$/.test(value)) {
    return true
  }
  if (/^-?\d+\.$/.test(value)) {
    return true
  }
  if (/^\.\d+$/.test(value)) {
    return true
  }
  return false
}

export class Amount {
  /**
   *
   * @param int Integer representation of the amount.
   * @param decimals Number of decimals.
   */
  protected constructor(readonly int: bigint, readonly decimals: number) {}

  /**
   *
   * Instantiates an amount based on it's integer representation.
   *
   * @param amount Integer representation of the amount.
   * @param tokenDecimals Number of decimals.
   */
  static fromInt(amount: number | bigint, decimals: number): Amount {
    if (typeof amount === 'number' && (!Number.isInteger(amount) || amount < 0)) {
      throw new Error('the amount argument must be a non-negative integer')
    } else if (typeof amount === 'bigint' && amount < 0) {
      throw new Error('the amount argument must be a non-negative integer')
    }
    if (!Number.isInteger(decimals) || decimals < 0) {
      throw new Error('the decimals argument must be a non-negative integer')
    }
    return new Amount(BigInt(amount), decimals)
  }

  /**
   * Instantiates an amount based on its number representation.
   *
   * @param amount Number representation of the amount.
   * @param tokenDecimals Number of decimals.
   */
  static fromNum(amount: number | string, decimals: number): Amount {
    if (typeof amount === 'number') {
      amount = amount.toString()
    }
    console.log(amount, isNumeric(amount))
    if (!isNumeric(amount)) {
      throw new Error('the amount argument must be a number')
    }
    const [int, dec] = amount.split('.')
    if (int.startsWith('-')) {
      throw new Error('the amount argument must be non-negative')
    }
    const decTrimmed = dec.replace(/0+$/, '')
    if (decTrimmed.length > decimals) {
      throw new Error(
        'the amount cannot be correctly represented with the provided number of decimals'
      )
    }

    return new Amount(BigInt(int + decTrimmed), decimals)
  }

  /**
   * Return true if amounts are equal.
   *
   * @param other
   * @returns
   */
  equals(other: Amount): boolean {
    return this.int === other.int && this.decimals === other.decimals
  }
}
