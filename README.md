# Flooph

Flooph is a Ruby library designed to let you take code from (possibly-malicious) users and evaluate it safely.
Instead of evaluating arbitrary Ruby code (or JavaScript, or any other interpreter), it specifies a custom 'language',
with its own parser and evaluation.

Flooph provides four core pieces of functionality:

* A simple syntax for specifying and saving key/value pairs (much like a Ruby Hash literal):

        f = Flooph.new
        f.update_variables <<-USERINPUT
          name: "World"
          cats: 17
          dogs: cats + 1
          alive: yes
          trollLocation: "cave"
        USERINPUT

* A simple template language that supports conditional content and injecting content.

        puts f.transform <<-ENDTEMPLATE
          Hello, {=name}!

          {?trollLocation="cave"}
          There is a troll glaring at you.
          {|}
          The air smells bad here, like rotting meat.
          {.}

          {?debug}Troll is at {=trollLocation}.{.}

          {?dogs>0}
          I own {=dogs} dogg{?dogs=1}y{|}ies{.} now.
          {.}

          {? cats=42 }
          I have exactly 42 cats! I'll never get more.
          {| cats=1 }
          I have a cat. If I get another, I'll have two.
          {| cats>1 }
          I have {=cats} cats.
          If I get another, I'll have {=cats+1}.
          {|}
          I don't have any cats.
          {.}
        ENDTEMPLATE
        #=> Hello, World!
        #=>
        #=> There is a troll glaring at you.
        #=>
        #=> I own 18 doggies now.
        #=>
        #=> I have 17 cats.
        #=> If I get another, I'll have 18.


* Standalone functionality for evaluating conditional expressions based on the key/values (also used in the templates).

        f = Flooph.new
        f.update_variables <<-USERINPUT
          cats: 17
          dogs: cats + 1
          alive: yes
          trollLocation: "cave"
        USERINPUT
        f.conditional 'cats?'                     #=> true
        f.conditional 'cats > 0'                  #=> true
        f.conditional 'cats ≥ 42'                 #=> false
        f.conditional 'dogs = cats'               #=> false
        f.conditional 'trollLocation = "cave"'    #=> true
        f.conditional 'alive & (cats>0 | dogs>0)' #=> true

* Standalone functionality for evaluating value expressions based on the key/values (also used in the templates).

        f = Flooph.new cats:17, dogs:25
        f.calculate 'cats + dogs'                 #=> 42

# Syntax Reference

## Template Syntax

**`{=expression}`** — value output

Calculate a value and place its result at this spot. You can have spaces inside and around the expression if you like, but the opening `{=` must not have a space between the characters.

The tag and expression must all be on the same line.


**`{?condition1}` contents1 `{.}`**
**`{?condition1}` contents1 `{|}` else_contents `{.}`**
**`{?condition1}` contents1 `{|condition2}` contents2 `{|condition3}` contents3 `{.}`**
**`{?condition1}` contents1 `{|condition2}` contents2 `{|condition3}` contents3 `{|}` else_contents `{.}`**

Conditional content must start with a `{?…}` condition tag. _(See [Condition Syntax](#condition-syntax) below for details on writing a condition.)_ You can have spaces inside and around the condition if you like, but the opening `{?` must not have a space between the characters.

Conditional content must end with a `{.}` tag. This must not have spaces within it.

Between the `{?…}` and `{.}` you can have any number of `{|…}` additional conditions. The first condition that evaluates to true will show the content following that.

After any `{|…}` additional conditions you can end with a final `{|}` else condition. The content following this tag will be shown if no other conditions evaluate to true.

While the contents of each `{?…}` and `{|…}` tag must be on the same line, you can have newlines in the contents between tags.

Contents may be raw text, or may contain additional tags. For example:

    {?dogs>0}I own {=dogs} dogg{?dogs=1}y{|}ies{.} now.{.}


## Condition Syntax

Conditions use:

* Numeric and string comparisons, using < > = == ≤ <= ≥ >= ≠ !=

   For example: `cat>0`, `loc="house"`, `dogs≠1`

   Comparisons involving variables that do not have a value (`zxyp < 8`)
   or comparisons between invalid types (`cats>"!@$#"`) evaluate to `false`.

 * Variable presence/truthiness using just name (`alive`) or with optional trailing question mark (`alive?`).

 * Boolean composition using `|` (alternatively `||`) and `&` (alternatively `&&`), with parentheses to alter precedence, and leading `!` to negate the value.

    For example: `alive | lifeCount>3 & (deaths<5 | !undead) || !(f && g)`

   * `!foo` means "not foo", inverting the meaning
   * `&` has higher precedence than `|`

      In other words `a | b & c` is the same as `a | (b & c)`.

## Value Expressions
_TODO_

## Variable Assignment
_TODO_


# Known Limitations (aka TODO)
_In decreasing priority…_

- Flooph does not provide good errors when parsing or evaluation fails.
- Tests are ad-hoc, and not integrated into any release process.
- Value expression language is a little _too_ simple; should support full arithmetic, including parens.
- Missing benchmarking to try speed improvements.
- Supplying custom `vars` to methods updates it for the instance; perhaps provide a one-off method.


# License & Contact
Flooph is copyright ©2018 by Gavin Kistner and is licensed under the [MIT License][1]. See the `LICENSE` file for more details.

For bugs or feature requests please open [issues on GitHub][2]. For other communication you can [email the author directly](mailto:gavin@phrogz.net?subject=Flooph).

[1]: http://opensource.org/licenses/MIT
[2]: https://github.com/Phrogz/Flooph/issues
