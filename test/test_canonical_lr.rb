require File.expand_path(File.join(__dir__, 'case'))

module Racc
  class TestCanonicalLR < TestCase
    GRAMMAR = <<~GRAMMAR
      class CanonicalLRTestParser
      rule
        target : s

        s : 'a' A 'd'
          | 'b' B 'd'
          | 'a' B 'u'
          | 'b' A 'u'

        A : 'c'

        B : 'c'
      end
    GRAMMAR

    def parsed_grammar
      Racc::GrammarFileParser.parse(GRAMMAR, 'canonical_lr.y').grammar
    end

    def test_canonical_state_identity_keeps_lookaheads_separate
      states = Racc::States.new(parsed_grammar, Racc::DebugFlags.new, true).dfa

      assert_equal 0, states.n_srconflicts
      assert_equal 0, states.n_rrconflicts
      assert_equal 17, states.size

      reduce_states = states.select do |state|
        state.closure.any? { |item| item.respond_to?(:pointer) && item.pointer.reduce? }
      end

      c_states = reduce_states.select do |state|
        state.closure.any? do |item|
          item.pointer.rule.target.value == :A || item.pointer.rule.target.value == :B
        end
      end

      assert_equal 2, c_states.size

      lookaheads = c_states.map do |state|
        state.closure.each_with_object({}) do |item, table|
          next unless item.pointer.reduce?
          table[item.pointer.rule.target.value] =
            item.each_la(states.grammar.symboltable).map(&:value)
        end
      end

      assert_include lookaheads, A: ['d'], B: ['u']
      assert_include lookaheads, A: ['u'], B: ['d']

      cores = c_states.map { |state| state.core.map { |item| item.pointer.ident } }
      assert_equal 1, cores.uniq.size

      pointer = states.grammar.each.find { |rule| rule.target.value == :A }.ptrs[0]
      states_with_a_head = states.select do |state|
        state.closure.any? do |item|
          item.pointer.ident == pointer.ident &&
            item.pointer.index == pointer.index
        end
      end
      assert_equal [[3, ['d']], [4, ['u']]],
                   states_with_a_head.map { |state|
                     item = state.closure.find do |candidate|
                       candidate.pointer.ident == pointer.ident
                     end
                     [state.ident, item.each_la(states.grammar.symboltable).map(&:value)]
                   }

      states_with_a_reduce = states.select do |state|
        state.core.any? { |item| item.pointer.rule.target.value == :A && item.pointer.reduce? }
      end
      assert_equal [[8, ['d']], [11, ['u']]],
                   states_with_a_reduce.map { |state|
                     item = state.core.find { |candidate| candidate.rule.target.value == :A }
                     [state.ident, item.each_la(states.grammar.symboltable).map(&:value)]
                   }
    end

    def test_lalr_merges_same_cores_and_reports_conflicts
      states = Racc::States.new(parsed_grammar, Racc::DebugFlags.new, false).dfa

      assert_equal 16, states.size
      assert_equal 2, states.n_rrconflicts
    end

    def test_grammar_option_selects_canonical_lr
      source = GRAMMAR.sub(/rule\n/, "options canonical_lr\nrule\n")
      grammar = Racc::GrammarFileParser.parse(source, 'canonical_lr.y').grammar
      states = grammar.states

      assert grammar.canonical_lr
      assert states.canonical_lr?
      assert_equal 17, states.size
    end
  end
end
