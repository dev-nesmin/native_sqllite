/// Compares nested lists and maps recursively using value equality.
bool deepCollectionEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;

  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!deepCollectionEquals(left[index], right[index])) return false;
    }
    return true;
  }

  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !deepCollectionEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }

  return left == right;
}

/// Computes a stable hash for nested lists and maps.
int deepCollectionHash(Object? value) {
  if (value is List) {
    return Object.hashAll(value.map(deepCollectionHash));
  }
  if (value is Map) {
    return Object.hashAllUnordered(
      value.entries.map(
        (entry) => Object.hash(
          deepCollectionHash(entry.key),
          deepCollectionHash(entry.value),
        ),
      ),
    );
  }
  return value.hashCode;
}
