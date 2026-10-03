class CanonicalLRParser
rule
  target : s

  s : 'a' A 'd' { result = :ad }
    | 'b' B 'd' { result = :bd }
    | 'a' B 'u' { result = :au }
    | 'b' A 'u' { result = :bu }

  A : 'c' { result = :c }

  B : 'c' { result = :c }
end
----inner

  def self.parse_string(input)
    parser = new
    parser.instance_variable_set(:@tokens, input.chars.map {|c| [c, nil] }.push([false, false]))
    parser.do_parse
  end

  def parse(tokens)
    @tokens = tokens
    do_parse
  end

  def next_token
    @tokens.shift
  end
----footer

if input = ENV['RACC_CANONICAL_LR_INPUT']
  expected = {
    "acd" => "ad",
    "bcd" => "bd",
    "acu" => "au",
    "bcu" => "bu"
  }.fetch(input)
  tokens = input.chars.map {|c| [c, nil] }.push([false, false])
  actual = CanonicalLRParser.new.parse(tokens).to_s
  abort unless actual == expected
  print actual
end
