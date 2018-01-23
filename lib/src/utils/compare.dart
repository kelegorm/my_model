library model.utils.compare;


/// More accurate implementation of equal function.
///
/// We need that function because we can meet infinity binding loop
/// when we erase input field. Value of empty input with type
/// "number" is NaN, but NaN != NaN in javascript.
bool equals( a, b ) {
  if (a == b) return true;
  /* The definition of equality for doubles is dictated by the IEEE 754 standard,
    which posits that NaNs do not obey the law of reflexivity. Given that hardware
    implements these rules, it is necessary to support them for reasons of efficiency.
    The definition of identity is not constrained in the same way. Instead, it
    assumes that bit-identical doubles are identical. */
  if (a is double && b is double && a.isNaN && b.isNaN) return true;
  return false;
}
