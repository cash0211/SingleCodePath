/// Produces a nil-padded zip sequence for source sequences of
/// potentially unequal lengths. The created sequence produces
/// a series of 2-arity tuples of optional elements, with the
/// shorter source sequence using `nil`-padding until the longer
/// sequence is consumed.
public struct NilPaddedZipSequence<Sequence1: Sequence, Sequence2: Sequence>
  : Sequence, IteratorProtocol {
  
  /// Advances to the next tuple and returns it, or `nil` if no both
  /// sequences have been exhausted. If only one sequence has been
  /// exhausted, it contributes `nil` to the tuple.
  ///
  /// Once `nil` has been returned, all subsequent calls return `nil`.
  public mutating func next() ->
    (Sequence1.Iterator.Element?, Sequence2.Iterator.Element?)? {
      let (element1, element2) = (_iter1?.next(), _iter2?.next())
      switch (element1, element2) {
      case (nil, nil): return nil
      case (_  , nil): _iter2 = nil
      case (nil,   _): _iter1 = nil
      default: break
      }
      return (element1, element2)
  }

  public init(_ sequence1: Sequence1, _ sequence2: Sequence2) {
    (_iter1, _iter2) = (sequence1.makeIterator(), sequence2.makeIterator())
  }
  
  private var (_iter1, _iter2): (Sequence1.Iterator?, Sequence2.Iterator?)
}

/// Zips two sequences of (potentially) different lengths.
///
/// This zipping operation produces a sequence of 2-arity tuples
/// with optional elements. When sequence lengths do not match, the shorter
/// sequence is padded with `nil` to match the length of the longer sequence.
/// For example:
///
/// ```
/// nilPaddedZip("abcd", 1..2)
///
/// // (Optional("a"), Optional(1)), (Optional("b"), Optional(2)),
/// // (Optional("c"), nil), (Optional("d"), nil)
/// ```
///
/// Passing a sequence with optional elements incorporates those elements
/// into the sequence:
///
/// ```
/// let optInts: [Int?] = [1, 5, nil, 3]
/// nilPaddedZip(optInts, 1...2))
///
/// // (Optional(Optional(1)), Optional(1)), (Optional(Optional(5)),
/// // Optional(2)), (Optional(nil), nil), (Optional(Optional(3)), nil)
/// ```
///
/// - Parameter sequence1: The first sequence.
/// - Parameter sequence2: The second sequence.
/// - Returns: a sequence of `(E1?,E2?)` tuples, corresponding to
///   the elements of each sequence. When exausted, the shorter sequence
///   pads its elements with nil.
public func nilPaddedZip<Sequence1, Sequence2>(
  _ sequence1: Sequence1,
  _ sequence2: Sequence2)
-> NilPaddedZipSequence<Sequence1, Sequence2>
     where Sequence1: Sequence, Sequence2: Sequence {
      return NilPaddedZipSequence(sequence1, sequence2)
}