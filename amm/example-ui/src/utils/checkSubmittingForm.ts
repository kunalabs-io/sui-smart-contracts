export const isSubmitFormDisabled = (args: {
  firstCoinType: string
  secondCoinType: string
  firstCoinValue: string
  secondCoinValue: string
  coinBalances?: Map<string, bigint>
}) => {
  const { firstCoinType, secondCoinType, firstCoinValue, secondCoinValue, coinBalances } = args

  if (!firstCoinValue || !secondCoinValue || !firstCoinType || !secondCoinType || firstCoinType === secondCoinType) {
    return true
  }

  if (BigInt(firstCoinValue) === 0n || BigInt(secondCoinValue) === 0n) {
    return true
  }

  if (coinBalances) {
    const firstCoinBalance = coinBalances.get(firstCoinType)
    const secondCoinBalance = coinBalances.get(secondCoinType)

    if (firstCoinBalance && secondCoinBalance) {
      return BigInt(firstCoinValue) > firstCoinBalance || BigInt(secondCoinValue) > secondCoinBalance
    }
  }

  return false
}
