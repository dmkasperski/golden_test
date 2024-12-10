bool xnor(List<bool> conditions) {
  // Count the number of `true` values in the list.
  int trueCount = conditions.where((c) => c).length;

  // Return true if all are true or all are false.
  return trueCount == 0 || trueCount == conditions.length;
}
