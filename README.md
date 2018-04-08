# Flooph

Flooph is a Ruby library designed to let you take code from (possibly-malicious) users and evaluate it safely.
Instead of evaluating arbitrary Ruby code (or JavaScript, or any other interpreter), it specifies a custom 'language',
with its own parser and evaluation.

Flooph provides four core pieces of functionality:

* A simple syntax for specifying and saving key/value pairs (much like a Ruby Hash literal):

        debug: false
        alive: yes
        cats: 17
        trollLocation: "cave"
        dogs: cats + 1

* A simple template language that supports conditional content and injecting content.

        Hello, {=name}!                                # insert values from variables
                                                       #
        {?trollLocation="cave"}                        # conditional based on boolean expressions
        There is a troll glaring at you.               #
        {|}                                            # conditional 'else' clause
        The air smells bad here, like rotting meat.    #
        {.}                                            # end of the if/else
                                                       #
        {?debug}Troll is at {=trollLocation}.{.}       # if the variable exists (and isn't false)
                                                       #
        {?dogs>0}                                      #
        I own {=dogs} dogg{?dogs=1}y{|}ies{.} now.     # conditionals can be inline
        {.}                                            #
                                                       #
        {? cats=42 }                                   #
        I have exactly 42 cats! I'll never get more.   #
        {| cats=1 }                                    # else-if for chained conditionals
        I have a cat. If I get another, I'll have two. #
        {| cats>1 }                                    #
        I have {=cats} cats.                           #
        If I get another, I'll have {=cats+1}.         # output can do simple addition/subtraction
        {|}                                            #
        I don't have any cats.                         #
        {.}                                            #

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

