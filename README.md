# Combinatorics

This is a simple Combinatorics Library.
It provides the following functions for the Collections Set, Multiset & Array:

- func combinations(choose: Int)
- func permutations()
- func permutations(choose: Int)
- func multicombinations(choose: Int)
- func multipermutations(choose: Int)
- func subsets()

They are implemented as Sequences so that they can be used as say:

  for comb in ["A","B","C"].combinations(choose: 2) {
    print(comb)
  }
