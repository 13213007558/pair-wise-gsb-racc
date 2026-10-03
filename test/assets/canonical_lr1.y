class CanonicalLR1Parser
rule
  target: a x 'd' { result = [:ad, val] }
        | a y 'e' { result = [:ae, val] }
        | b x 'e' { result = [:be, val] }
        | b y 'd' { result = [:bd, val] }

  a: 'a' { val[0] }
  b: 'b' { val[0] }
  x: 'c' { result = :x }
  y: 'c' { result = :y }
end

---- header
require 'strscan'

---- inner

def parse(input)
  @scanner = StringScanner.new(input)
  do_parse
end

def next_token
  @scanner.skip(/\s+/)
  token = @scanner.getch
  token && [token, token]
end

---- footer

cases = {
  'a c d' => [:ad, ['a', :x, 'd']],
  'a c e' => [:ae, ['a', :y, 'e']],
  'b c d' => [:bd, ['b', :y, 'd']],
  'b c e' => [:be, ['b', :x, 'e']]
}

cases.each do |input, expected|
  result = CanonicalLR1Parser.new.parse(input)
  name, values = result
  raise "#{input.inspect}: #{result.inspect}" unless name == expected[0]
  raise "#{input.inspect}: #{result.inspect}" unless values == expected[1]
end

puts 'ok'
