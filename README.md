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

