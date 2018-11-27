# Combinatorics

This is a simple Combinatorics Library.
It provides the following functions for the Collections Set, Multiset & Array:

- func combinations(choose: Int)
- func permutations()
- func permutations(choose: Int)
- func multicombinations(choose: Int)
- func multipermutations(choose: Int)
- func subsets()

They are implemented as Sequences so:
  for comb in ["A","B","C"].combinations(choose: 2) {
    print(comb)
  }

Repeated outputs are handled as multicombinations (i.e. multicombinations of a set):
["A", "B", "C"].multicombinations(choose: 2) is:

["A", "A"]
["A", "B"]
["A", "C"]
["B", "B"]
["B", "C"]
["C", "C"]

Unusually it handles repeated inputs.  (i.e. Combinations of a multiset):
["A", "A", "A", "B", "B", "C"].combinations(choose: 3) is:
["A", "A", "A"]
["A", "A", "B"]
["A", "B", "B"]
["A", "A", "C"]
["A", "B", "C"]
["B", "B", "C"]
