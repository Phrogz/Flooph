require 'parslet'

class Flooph < Parslet::Parser
  # The current values used when evaluating templates and conditionals.
  # Can also be updated by user input using #update_variables.
  attr_accessor :vars

  # Create a new, reusable template parser and evaluator.
  #
  # @param vars [Hash] symbol-to-values used in templates and conditional evaluations.
  def initialize(vars={})
    super()
    @vars = vars
  end

  # Evaluate a template like the following example, inserting content and
  # evaluating conditional branches. If you don't supply `vars` then the
  # existing values for the instance are used.
  #
  #     Hello, {=name}!                                # Insert values from variables.
  #                                                    #
  #     {?trollLocation="cave"}                        # Conditional based on boolean expressions.
  #     There is a troll glaring at you.               # See #conditional for how to write conditions.
  #     {|}                                            # Conditional 'else' clause.
  #     The air smells bad here, like rotting meat.    #
  #     {.}                                            # End of the if/else.
  #                                                    #
  #     {?debug}Troll is at {=trollLocation}.{.}       # Conditional based on if the variable exists (and isn't false)
  #                                                    #
  #     {?dogs>0}                                      #
  #     I own {=dogs} dogg{?dogs=1}y{|}ies{.} now.     # Conditionals can be inline.
  #     {.}                                            #
  #                                                    #
  #     {? cats=42 }                                   #
  #     I have exactly 42 cats! I'll never get more.   #
  #     {| cats=1 }                                    # Else-if for chained conditionals.
  #     I have a cat. If I get another, I'll have two. #
  #     {| cats>1 }                                    #
  #     I have {=cats} cats.                           #
  #     If I get another, I'll have {=cats+1}.         # Output can do simple addition/subtraction.
  #     {|}                                            #
  #     I don't have any cats.                         #
  #     {.}                                            #
  #
  # @param vars [Hash] variable values to use for this and future evaluations.
  #        If omitted, existing variable values will be used.
  #        (see also #vars and #update_variables)
  # @return [String] the template after transformation.
  def transform(str, vars=nil)
    parse_and_transform(:mkup, str, vars).tap do |result|
      result.gsub!(/\n{3,}/, "\n\n") if result
    end
  end

  # Evaluate simple conditional expressions to a boolean value, with variable lookup.
  # Examples:
  #
  #     cats?            # variable cats is set (and not set to `false` or `no`)
  #     cats = 42        # variable `cats` equals 42
  #     cats>0 & dogs>0  # if both variables are numbers greater than zero
  #
  # * Numeric and string comparisons, using < > = == ≤ <= ≥ >= ≠ !=
  #   * Non-present variables or invalid comparisons always result in false
  # * Variable presence/truthiness using just name (isDead) or with optional trailing question mark (isDead?).
  # * Boolean composition using a | b & c & (d | !e) || !(f && g)
  #   * !foo means "not foo", inverting the meaning
  #   * & has higher precedence than |
  #   * | is the same as ||; & is the same as &&
  #
  # @param vars [Hash] variable values to use for this and future evaluations.
  #        If omitted, existing variable values will be used.
  #        (see also #vars and #update_variables)
  # @return [true, false] the result of the evaluation.
  def conditional(str, vars=nil)
    parse_and_transform(:boolean_expression, str, vars)
  end

  # Parse a simple hash setup for setting and updating values. For example:
  #
  #     s = Flooph.new  # No variables yet
  #     s.update_variables <<-END
  #       debug: false
  #       cats: 17
  #       alive: yes
  #       trollLocation: "cave"
  #     END
  #     s.conditional "cats > 3"
  #     #=> true
  #     s.update_variables "oldCats:cats \n cats: cats + 1"
  #     s.calculate "cats"
  #     #=> 18
  #     s.calculate "oldCats"
  #     #=> 17
  #
  # Legal value types are:
  #
  # * Booleans:  `true`, `false`, `yes`, `no`
  # * Numbers:   `-3`, `12`, `3.1415`
  # * Strings:   `"foo"`, `"Old Barn"` _must use double quotes_
  # * Variables: `cats + 7` _only supports add/subtract, not multiplication_
  #
  # @param vars [Hash] initial variable values to base references on.
  #        If omitted, existing variable values will be used.
  # @return [Hash] the new variable values after updating.
  def update_variables(str, vars=nil)
    parse_and_transform(:varset, str, vars)
    @vars
  end

  # Evaluate an expression, looking up values and performing simple math.
  #
  #     s = Flooph.new cats:17, dogs:25
  #     p s.calculate("cats + dogs")
  #     #=> 42
  #
  # @param vars [Hash] variable values to use for this and future evaluations.
  #        If omitted, existing variable values will be used.
  #        (see also #vars and #update_variables)
  # @return [Hash] the new variable values after updating.
  def calculate(str, vars=nil)
    parse_and_transform(:value, str, vars)
  end

  # Common implementation for other methods
  # @!visibility private
  def parse_and_transform(root_rule, str, vars)
    @vars = vars if vars
    begin
      str = str.strip.gsub(/^[ \t]+|[ \t]+$/, '')
      tree = send(root_rule).parse(str)
      Transform.new.eval(tree, @vars)
    rescue Parslet::ParseFailed => error
      puts "Flooph failed to parse #{str.inspect}"
      puts error.parse_failure_cause.ascii_tree
      puts
      # TODO: catch transformation errors
    end
  end

  # template
  rule(:mkup) { (proz | spit.as(:proz) | cond).repeat.as(:result) }
  rule(:proz) { ((str('{=').absent? >> str('{?').absent? >> str('{|').absent? >> str('{.}').absent? >> any).repeat(1)).as(:proz) }
  rule(:spit) { str('{=') >> sp >> value >> sp >> str('}') }
  rule(:cond) do
    test.as(:test)  >> mkup.as(:out)                    >>
    (elif.as(:test) >> mkup.as(:out)).repeat.as(:elifs) >>
    (ells >> mkup.as(:proz)).repeat(0,1).as(:else)      >>
    stop
  end
  rule(:test) { str('{?') >> sp >> boolean_expression >> sp >> str('}') }
  rule(:elif) { str('{|') >> sp >> boolean_expression >> sp >> str('}') }
  rule(:ells) { str('{|}') }
  rule(:stop) { str('{.}') }

  # conditional
  rule(:boolean_expression) { orrs }
  rule(:orrs)  { ands.as(:and) >> (sp >> str('|').repeat(1,2) >> sp >> ands.as(:and)).repeat.as(:rest) }
  rule(:ands)  { bxpr.as(:orr) >> (sp >> str('&').repeat(1,2) >> sp >> bxpr.as(:orr)).repeat.as(:rest) }
  rule(:bxpr) do
                 ((var.as(:lookup) | num | text).as(:a) >> sp >> cmpOp.as(:cmpOp) >> sp >> (var.as(:lookup) | num | text).as(:b)) |
                 (str('!').maybe.as(:no) >> var.as(:lookup) >> str('?').maybe) |
                 (str('!').maybe.as(:no) >> str('(') >> sp >> orrs.as(:orrs) >> sp >> str(')'))
  end
  rule(:cmpOp) { (match['<>='] >> str('=').maybe) | match['≤≥≠'] | str('!=') }

  # assignment
  rule(:varset){ pair >> (match("\n") >> pair.maybe).repeat }
  rule(:pair)  { var.as(:set) >> sp >> str(':') >> sp >> value.as(:val) >> sp }
  rule(:value) { bool | adds | num | text | var.as(:lookup) }
  rule(:adds)  { (var.as(:lookup) | num).as(:a) >> sp >> match['+-'].as(:addOp) >> sp >> (var.as(:lookup) | num).as(:b) }
  rule(:sp)    { match[' \t'].repeat }

  # shared
  rule(:bool)  { (str('true') | str('false') | str('yes') | str('no')).as(:bool) }
  rule(:text)  { str('"') >> match["^\"\n"].repeat.as(:text) >> str('"') }
  rule(:num)   { (str('-').maybe >> match['\d'].repeat(1) >> (str('.') >> match['\d'].repeat(1)).maybe).as(:num) }
  rule(:var)   { match['a-zA-Z'] >> match('\w').repeat }
  rule(:sp)    { match[' \t'].repeat }

  class Transform < Parslet::Transform
    rule(proz:simple(:s)){ s.to_s }
    rule(test:simple(:test), out:simple(:out), elifs:subtree(:elifs), else:subtree(:elseout)) do
      if test
        out
      elsif valid = elifs.find{ |h| h[:test] }
        valid[:out]
      else
        elseout[0]
      end
    end
    rule(result:sequence(:a)){ a.join }

    # conditional
    rule(a:simple(:a), cmpOp:simple(:op), b:simple(:b)) do
      begin
        case op
          when '<'       then a<b
          when '>'       then a>b
          when '=', '==' then a==b
          when '≤', '<=' then a<=b
          when '≥', '>=' then a>=b
          when '≠', '!=' then a!=b
        end
      rescue NoMethodError, ArgumentError
        # nil can't compare with anyone, and we can't compare strings and numbers
        false
      end
    end
    rule(orr:simple(:value)) { value }
    rule(and:simple(:value)) { value }
    rule(orr:simple(:first), rest:sequence(:rest)) { [first, *rest].all? }
    rule(and:simple(:first), rest:sequence(:rest)) { [first, *rest].any? }
    rule(no:simple(:invert), orrs:simple(:val)) { invert ? !val : val }
    rule(no:simple(:invert), lookup:simple(:s)){ v = vars[s.to_sym]; invert ? !v : v }

    # assignment
    rule(set:simple(:var), val:simple(:val)){ vars[var.to_sym] = val }
    rule(a:simple(:a), addOp:simple(:op), b:simple(:b)) do
      x = a.is_a?(Parslet::Slice) ? vars[a.to_sym] : a
      y = b.is_a?(Parslet::Slice) ? vars[b.to_sym] : b
      if x.nil? || y.nil?
        nil
      else
        case op
          when '+' then x+y
          when '-' then x-y
        end
      end
    end

    # shared
    rule(lookup:simple(:s)) { vars[s.to_sym] }
    rule(num:simple(:str)) { f=str.to_f; i=str.to_i; f==i ? i : f }
    rule(bool:simple(:s)){ d = s.str.downcase; d=='true' || d=='yes' }
    rule(text:simple(:s)){ s.str }

    def eval(tree, vars)
      apply(tree, vars:vars)
    end
  end
end
