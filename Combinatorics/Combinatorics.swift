//
//  Combinatorics.swift
//  Combinatorics
//
//  Created by Adahus on 17/11/2018.
//  Copyright © 2018 Adhus. All rights reserved.
//

//====================================================
// Supporting Structures:
//====================================================

//----------------------------------------------------------------
// Initializable Collections

protocol InitializableCollection: Collection {
  init<S : Sequence>(_ elements: S) where S.Element == Element
}

extension Array: InitializableCollection { }
extension Set: InitializableCollection { }
extension Multiset: InitializableCollection { }

//----------------------------------------------------------------
// Distinctable
// This provides a uniform interface to collections: Multiset, Set and Array to provide an array of their distinct elements.

protocol Distinctable: Collection where Element: Hashable {
  func distinctElements() -> [Element]
}

// Multiset already provides this function
extension Multiset: Distinctable {
  func distinctElements() -> [Element] {
    return Array(distinct())
  }
}

// Set can just iterate over it's elements because they are distinct by the definition of a Set.
extension Set: Distinctable {
  func distinctElements() -> [Element] {
    return Array(self)
  }
}
// An Array might have repeated Elements so we can convert to Set and then back to Array.
extension Array: Distinctable where Element: Hashable {
  func distinctElements() -> [Element] {
    return Array(Set(self))
  }
}

//----------------------------------------------------------------
//extension Array where Element: Equatable {
//  func encode() -> [Int] {
//    return map { self.firstIndex(of: $0)! }
//  }
//}
//
//extension Array where Element == Int {
//  func decode<Output>(_ original: [Output]) -> [Output] {
//    return map { original[$0] }
//  }
//}
//
//----------------------------------------------------------------
struct Lookup<Element> {
  var distinct: [Element]
  var indices: [Int]
}

protocol LookupableCollection: Collection {
  func asLookup() -> Lookup<Element>
}

extension Set: LookupableCollection {
  func asLookup() -> Lookup<Element> {
    return Lookup(distinct: Array(self), indices: Array(0..<count))
  }
}

extension Multiset: LookupableCollection {
  func asLookup() -> Lookup<Element> {
    var map: [Element] = []
    var ref: [Int] = []
    var index = 0
    for (element, count) in grouped() {
      map.append(element)
      for _ in 1...count {
        ref.append(index)
      }
      index += 1
    }
    return Lookup(distinct: map, indices: ref)
  }
}

extension Array: LookupableCollection where Element: Hashable {
  func asLookup() -> Lookup<Element> {
    return Multiset<Element>(self).asLookup()
  }
}

// Usage is ["A","B","C"][[0,2]] -> ["A","C"]
extension Array {
  subscript<Indices: Sequence>(indices: Indices) -> [Element] where Indices.Iterator.Element == Int {
    var result = [Element]()
    for index in indices {
      if index < count {
        result.append(self[index])
      }
    }
    return result
  }
}

//====================================================
// Combinations:
//====================================================

//----------------------------------------------------------------
// CombinatableCollection

// We need:
//   1) InputCollection to be Lookupable so that the collection can be turned into a lookup for generic combinatorics
//   2) OutputCollection to be Initializable so that we can instantiate it
protocol CombinatableCollection: LookupableCollection where InputCollection == Self, InputCollection.Element == OutputCollection.Element {
  associatedtype InputCollection
  associatedtype OutputCollection: InitializableCollection
  func combinations(choose: Int) -> _CombiIterator<InputCollection, OutputCollection>
}

extension CombinatableCollection {
  func combinations(choose: Int) -> _CombiIterator<InputCollection, OutputCollection> {
    let lookup: Lookup<Element> = asLookup()
    return _CombiIterator<InputCollection, OutputCollection>(lookup: lookup, choose: choose)
  }
}

struct _CombiIterator<InputCollection: LookupableCollection, OutputCollection: InitializableCollection> : Sequence, IteratorProtocol
  where InputCollection.Element == OutputCollection.Element {
  var distinct: [InputCollection.Element]
  var iter: AnyIterator<[Int]>

  init(lookup: Lookup<InputCollection.Element>, choose: Int) {
    distinct = lookup.distinct
    iter = lookup.indices._combinations(k: choose)
  }

  mutating func next() -> OutputCollection? {
    guard let current = iter.next() else { return nil }
    return OutputCollection(current.map { distinct[$0] })
  }
}

extension Set: CombinatableCollection {
  typealias InputCollection = Set
  typealias OutputCollection = Set
}

extension Multiset: CombinatableCollection {
  typealias InputCollection = Multiset
  typealias OutputCollection = Multiset
}

extension Array: CombinatableCollection where Element: Hashable {
  typealias InputCollection = Array
  typealias OutputCollection = Array
}

//----------------------------------------------------------------
/// MulticombinatableCollection

// We need:
//   1) InputCollection to be Lookupable so that the collection can be turned into a lookup for generic combinatorics
//   2) OutputCollection to be Initializable so that we can instantiate it
protocol MulticombinatableCollection: LookupableCollection, Distinctable where InputCollection == Self, InputCollection.Element == OutputCollection.Element {
  associatedtype InputCollection
  associatedtype OutputCollection: InitializableCollection
  func multicombinations(choose: Int) -> _MulticombiIterator<InputCollection, OutputCollection>
}

extension MulticombinatableCollection where Element: Hashable {
  func multicombinations(choose: Int) -> _MulticombiIterator<InputCollection, OutputCollection> {
    let lookup: Lookup<Element> = distinctElements().asLookup()
    return _MulticombiIterator<InputCollection, OutputCollection>(lookup: lookup, k: choose)
  }
}

extension Set: MulticombinatableCollection { }
extension Multiset: MulticombinatableCollection { }
extension Array: MulticombinatableCollection where Element: Hashable { }

struct _MulticombiIterator<InputCollection: LookupableCollection, OutputCollection: InitializableCollection> : Sequence, IteratorProtocol
where InputCollection.Element == OutputCollection.Element, InputCollection: Distinctable {
  var lookup: [InputCollection.Element]
  var iter: AnyIterator<[Int]>
  
  init(lookup: Lookup<InputCollection.Element>, k: Int) {
    self.lookup = lookup.distinct.distinctElements()
    iter = lookup.indices._multicombinations(k: k)
  }
  
  mutating func next() -> OutputCollection? {
    guard let current = iter.next() else { return nil }
    return OutputCollection(current.map { lookup[$0] })
  }
}

//====================================================
// Permutations:
//====================================================

//----------------------------------------------------------------
// PermutatableCollection

protocol PermutatableCollection: CombinatableCollection {
  func permutations(choose: Int) -> _PermiIterator<Element>
  func permutations() -> _PermiIterator<Element>
}

extension PermutatableCollection {
  func permutations(choose: Int) -> _PermiIterator<Element> {
    return _PermiIterator(lookup: asLookup(), choose: choose)
  }
  func permutations() -> _PermiIterator<Element> {
    return permutations(choose: count)
  }
}

extension Set: PermutatableCollection { }
extension Multiset: PermutatableCollection { }
extension Array: PermutatableCollection where Element: Hashable { }

struct _PermiIterator<Element> : Sequence, IteratorProtocol {
  var lookup: [Element]
  var iterComb: AnyIterator<[Int]>
  var combination: [Int]?
  var iterPerm: AnyIterator<[Int]>!
  
  init(lookup: Lookup<Element>, choose: Int) {
    self.lookup = lookup.distinct
    iterComb = lookup.indices._combinations(k: choose)
    combination = nil
  }

  mutating func next() -> [Element]? {
    while true {
      if combination == nil {
        combination = iterComb.next()
        if combination == nil { return nil }
        iterPerm = combination!._permutations()
      }
      if let permutation = iterPerm.next() {
        return permutation.map { lookup[$0] }
      }
      combination = nil
    }
  }
  
}

//----------------------------------------------------------------
// MultipermutatableCollection

protocol MultipermutatableCollection: PermutatableCollection, Distinctable {
  func multipermutations(choose: Int) -> _MultipermiIterator<Element>
  func multipermutations() -> _MultipermiIterator<Element>
}

extension MultipermutatableCollection where Element: Hashable  {
  func multipermutations(choose: Int) -> _MultipermiIterator<Element> {
    return _MultipermiIterator(lookup: asLookup(), choose: choose)
  }
  func multipermutations() -> _MultipermiIterator<Element> {
    return multipermutations(choose: count)
  }
}

extension Set: MultipermutatableCollection { }
extension Multiset: MultipermutatableCollection { }
extension Array: MultipermutatableCollection where Element: Hashable { }

struct _MultipermiIterator<Element> : Sequence, IteratorProtocol where Element: Hashable {
  var lookup: [Element]
  var iterMulticomb: AnyIterator<[Int]>
  var multicombination: [Int]?
  var iterPerm: AnyIterator<[Int]>!
  
  init(lookup: Lookup<Element>, choose: Int) {
    self.lookup = lookup.distinct.distinctElements()
    iterMulticomb = lookup.indices._multicombinations(k: choose)
    multicombination = nil
  }
  
  mutating func next() -> [Element]? {
    while true {
      if multicombination == nil {
        multicombination = iterMulticomb.next()
        if multicombination == nil { return nil }
        iterPerm = multicombination!._permutations()
      }
      if let permutation = iterPerm.next() {
        return permutation.map { lookup[$0] }
      }
      multicombination = nil
    }
  }
  
}
//====================================================
// Subsets:
//====================================================

//----------------------------------------------------------------
// SubsetableCollection

// We need:
//   1) InputCollection to be Lookupable so that the collection can be turned into a lookup for generic combinatorics
//   2) OutputCollection to be Initializable so that we can instantiate it
protocol SubsetableCollection: LookupableCollection where InputCollection == Self, InputCollection.Element == OutputCollection.Element {
  associatedtype InputCollection
  associatedtype OutputCollection: InitializableCollection
  func subsets() -> _SubsetIterator<InputCollection, OutputCollection>
}

extension SubsetableCollection {
  func subsets() -> _SubsetIterator<InputCollection, OutputCollection> {
    return _SubsetIterator(lookup: asLookup())
  }
}

extension Set: SubsetableCollection { }
extension Multiset: SubsetableCollection { }
extension Array: SubsetableCollection where Element: Hashable { }

struct _SubsetIterator<InputCollection: LookupableCollection, OutputCollection: InitializableCollection> : Sequence, IteratorProtocol
where InputCollection.Element == OutputCollection.Element {
  var lookup: [InputCollection.Element]
  var iterComb: AnyIterator<[Int]>?
  var multiset: [Int]
  var k: Int
  var n: Int
  
  init(lookup: Lookup<InputCollection.Element>) {
    self.lookup = lookup.distinct
    n = lookup.indices.count
    k = 0
    multiset = lookup.indices
    iterComb = multiset._combinations(k: k)
  }
  
  mutating func next() -> OutputCollection?  {
    while true {
      if let current = iterComb?.next() {
        return OutputCollection(current.map { lookup[$0] })
      }
      guard k < n else { return nil }
      k += 1
      iterComb = multiset._combinations(k: k)
    }
  }

}

//====================================================
// Wordplay:
//====================================================

//====================================================
// Anagrams:

extension String {
  func anagrams() -> _PermiStringIterator {
    return _PermiStringIterator(string: self, choose: count)
  }

  func subgrams(ofLength length: Int) -> _PermiStringIterator {
    return _PermiStringIterator(string: self, choose: length)
  }
}

internal struct _PermiStringIterator : Sequence, IteratorProtocol {
  var permiIterator: _PermiIterator<Character>
  
  init(string: String, choose: Int) {
    let chars: [Character] = Array(string)
    permiIterator = chars.permutations(choose: choose)
  }
  
  mutating func next() -> String? {
    guard let chars: [Character] = permiIterator.next() else { return nil }
    return String(chars)
  }
  
}

//----------------------------------------------------------------
// COMBINATORICS CORE
//----------------------------------------------------------------
// THESE ROUTINES ONLY WORK CORRECTLY WITH ARRAYS OF INTEGERS WHERE THE INTEGERS ARE INCREASING IN THE ARRAY
//  i.e. if i > j then array[i] > array[j]
// They are not designed to be used directly but only for internal use by the other combinatorics function
//----------------------------------------------------------------

//----------------------------------------------------------------
// Combinations

extension Array where Element == Int {
  // For combinations (and this will be passed on to permutations):
  // 1. If k=0 then return array of length 0: []
  // 2. If k>n then return nil
  // 3. return array of length k
  
  func _combinations(k: Int) -> AnyIterator<[Element]> {
    let nminusk = count - k
    var multiset = self
    var current = Array(multiset.prefix(k))
    var firstCombination = true
    var ended = false
    
    return AnyIterator {
      if ended { return nil }
      if firstCombination {
        if k == 0 {
          ended = true
          return []
        }
        if k > self.count {
          ended = true
          return nil
        }
        firstCombination = false
        return current
      }
      var index = k - 1  // Index of last element of choose.
      while true {
        // Find the rightmost element indices[index] that is less than the maximum value it can have which is (n – k + i)
        if (current[index] < multiset[nminusk + index]) {
          // Find the successor
          var j = 0
          while multiset[j] <= current[index] {
            j += 1
          }
          // Replace this element with it
          current[index] = multiset[j]
          if (index < k - 1) {
            // Make the elements after it the same as this part of the multiset
            for l in index+1 ..< k {
              j += 1
              current[l] = multiset[j]
            }
            //Possible replacement of above 3 lines: current[index+1..<k ] = multiset[j..<j+k-index]
          }
          return current
        }
        if index == 0 {
          ended = true
          return nil
        }
        index -= 1
      }
    }
  }
}

//----------------------------------------------------------------
// Multicombinations

// For multicombinations (and this will be passed on to multipermutations):
// 1. If k=0 then return array of length 0: [] just once and then stop.
// 2. If n=0 then return nil from now on.
// 3. return array of length k possibly repeatedly.

// This function assumes that all elements are distinct
// Multicombinations of a multiset is required then this is handled in the higher level routines
extension Array where Element == Int {
  func _multicombinations(k: Int) -> AnyIterator<[Element]> {
    var current = Array(repeating: 0, count: k)
    var firstMulticombination = true
    var ended = false
    //    print("===>\(count)")
    
    return AnyIterator {
      if ended { return nil }
      if firstMulticombination {
        if k == 0 {
          ended = true
          return []
        }
        // No need to check for k > n because with multicombinations that isn't necessary.
        // but we do need to check for n = 0:
        if self.count == 0 {
          ended = true
          return nil
        }
        firstMulticombination = false
        return current
      }
      // Find the rightmost element that is less than n – 1
      var i = k - 1
      while i >= 0 {
        if current[i] < self.count - 1 {
          // Increment this element
          current[i] += 1
          if i < k - 1 {
            // Make the elements after it the same
            for j in i+1 ..< k {
              current[j] = current[j-1]
            }
          }
          return current
        }
        i -= 1
      }
      // Reset to first combination
      for i in 0 ..< k {
        current[i] = 0
      }
      return nil
    }
  }
}

//----------------------------------------------------------------
// Permutations

extension Array where Element == Int {
  func _permutations() -> AnyIterator<[Element]> {
    var current = self
    var firstPermutation = true
    
    return AnyIterator {
      guard self.count >= 0 else { return nil }
      
      if firstPermutation {
        firstPermutation = false
        guard self.count > 0 else { return [] }
        return current
      }
      guard self.count > 0 else { return nil }
      
      // Nothing to do for empty or single-element arrays:
      if self.count <= 1 {
        return nil
      }
      
      // L2: Find last j such that current[j] < current[j+1]. Terminate if no such j exists.
      var j = self.count - 2
      while j >= 0 && current[j] >= current[j+1] {
        j -= 1
      }
      if j == -1 {
        // Reverse elements 0...k to bring back to the first permutation
        var lo = 0
        var hi = self.count - 1
        while lo < hi {
          current.swapAt(lo, hi)
          lo += 1
          hi -= 1
        }
        //firstPermutation = true
        return nil
      }
      
      // L3: Find last l such that self[j] < self[l], then exchange elements j and l:
      var l = self.count - 1
      while current[j] >= current[l] {
        l -= 1
      }
      current.swapAt(j, l)
      
      // L4: Reverse elements j+1 ... count-1:
      var lo = j + 1
      var hi = self.count - 1
      while lo < hi {
        current.swapAt(lo, hi)
        lo += 1
        hi -= 1
      }
      return current
    }
  }
  
}

//----------------------------------------------------------------

