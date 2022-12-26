import { Amount } from './amount'
import { it, describe, expect } from 'vitest'

describe('Amount', () => {
  it('initializes from int', () => {
    let amt = Amount.fromInt(5, 2)
    expect(amt.int).toEqual(5n)
    expect(amt.decimals).toEqual(2)

    amt = Amount.fromInt(5n, 2)
    expect(amt.int).toEqual(5n)
    expect(amt.decimals).toEqual(2)
  })

  it('initializes from dec', () => {
    let amt = Amount.fromNum(0.05, 2)
    expect(amt.int).toEqual(5n)
    expect(amt.decimals).toEqual(2)

    amt = Amount.fromNum('0.05', 2)
    expect(amt.int).toEqual(5n)
    expect(amt.decimals).toEqual(2)

    amt = Amount.fromNum('0.0500', 2)
    expect(amt.int).toEqual(5n)
    expect(amt.decimals).toEqual(2)
  })

  it('.fromInt throws when the `decimals` argument is not a non-negative integer', () => {
    expect(() => Amount.fromInt(5, 0.2)).toThrow(
      'the decimals argument must be a non-negative integer'
    )
    expect(() => Amount.fromInt(5, -2)).toThrow(
      'the decimals argument must be a non-negative integer'
    )
  })

  it('.fromInt throws when the `intAmount` argument is not a non-negative integer', () => {
    expect(() => Amount.fromInt(5.5, 2)).toThrow(
      'the amount argument must be a non-negative integer'
    )
  })

  it('.fromNum throws when the amount is not non-negative', () => {
    expect(() => Amount.fromNum(-5, 2)).toThrow('the amount argument must be non-negative')
    expect(() => Amount.fromNum('-5', 2)).toThrow('the amount argument must be non-negative')
  })

  it('.fromDec throws when amount cannot be represented with the specified decimals', () => {
    expect(() => Amount.fromNum(0.005, 2)).toThrow(
      'the amount cannot be correctly represented with the provided number of decimals'
    )
    expect(() => Amount.fromNum('0.005', 2)).toThrow(
      'the amount cannot be correctly represented with the provided number of decimals'
    )
  })
})
