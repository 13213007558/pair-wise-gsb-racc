class CanonicalLR1ConflictParser
rule
  target: a { :a }
        | b { :b }
  a: 'c' { :a }
  b: 'c' { :b }
end
