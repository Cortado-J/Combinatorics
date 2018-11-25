# Combinatorics

This is a simple Combinatorics Library.
It provides the following functions for the Collections Set, Multiset & Array:

- func combinations(k: Int)
- func permutations()
- func permutations(k: Int)
- func multicombinations(k: Int)
- func multipermutations(k: Int)
- func subsets()

They are implemented as Sequences so that they can be used as say:

  for comb in ["A","B","C"].combinations(choose: 2) {
    print(comb)
  }
