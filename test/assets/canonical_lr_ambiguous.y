class CanonicalAmbiguousParser
rule
  target : A

  A : 'x' { result = :one }
    | 'x' { result = :two }
end
