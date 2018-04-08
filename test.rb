require_relative 'flooph'

def run!
  test_conditional
  test_assignments
  test_template
  test_interactions
end

def test_interactions
  f = Flooph.new  # No variables yet
  f.update_variables <<-END
    debug: false
    cats: 17
    alive: yes
    trollLocation: "cave"
  END
  f.conditional "cats > 3"  # true
  f.update_variables "cats: cats + 1"
  p f.calculate("cats")
end

def test_assignments
  tests = {
    '
    foo:true
    name: "Gavin"
    long: "Gavin Kistner"
    hasSeen: no
    bar: 17
    gor: kbo+kbo
    yay: jim + 0
    jim: jim + 1
    sam: 1 + bar
    jam : bar - 1
    jar : jam
    zoo : jam - 16
    cats: -1.3431
    diff: 10-8
    ' => {
      foo: true,
      name: 'Gavin',
      long: 'Gavin Kistner',
      hasSeen: false,
      bar: 17,
      jim: 2,
      yay: 1,
      sam: 18,
      jam: 16,
      jar: 16,
      cats: -1.3431,
      diff: 2,
      zoo: 0,
      gor: nil
    }
  }

  f = Flooph.new
  tests.each do |str, expected|
    f.vars = {}
    actual = f.update_variables(str, {jim:1} )
    compare_hashes expected, actual
  end
end

def test_conditional

  tests = {
    'a & b & c'         => true,
    '!a & b & c'        => false,
    'foo < 100'         => true,
    'foo < 100.1'       => true,
    'foo < 42'          => false,
    'foo≤42 & foo≥42 && foo==42 & !(foo≠42)' => true,
    'cats < 12'         => false,
    'cats > 12'         => false,
    'cats = 12'         => false,
    'a | b | c'         => true,
    '!a | b | c'        => true,
    '!a | !b | !c'      => false,
    'foo'               => true,
    'foo?'              => true,
    'foo<17 | bar?'     => true,
    'cat?'              => false,
    '!foo'              => false,
    '(foo)'             => true,
    '!(foo)'            => false,
    'a<b && b<c'        => true,
    'a>b && b<c'        => false,
    'a & no'            => false,
    'no & a'            => false,
    '(a & no)'          => false,
    ' (a & no) & (b|c)' => false,
    '!(a & no) & (b&c)' => true,
    '(a & no) | (b|c)'  => true,
    '(a & no) | (b&c)'  => true,
    'name="Phrogz"'     => true,
    'name="Gavin"'      => false,
    'a>"Phrogz"'        => false,
    'a="Phrogz"'        => false,
    'a<"Phrogz"'        => false,
    'name<"Phrogz"'     => false,
    'name>"Phrogz"'     => false,
    'name<"ZZZ"'        => true,
    'name<"AAA"'        => false,
    'name>"ZZZ"'        => false,
    'name>"AAA"'        => true,
    '"Phrogz">a'        => false,
    '"Phrogz"=a'        => false,
    '"Phrogz"<a'        => false,
    '"Phrogz"=name'     => true,
    '"Gavin"=name'      => false,
    '"Phrogz"<name'     => false,
    '"Phrogz">name'     => false,
    '"ZZZ"<name'        => false,
    '"AAA"<name'        => true,
    '"ZZZ">name'        => true,
    '"AAA">name'        => false,
  }

  f = Flooph.new
  tests.each do |expression, expected|
    f.vars = {name:'Phrogz', foo:42, bar:true, a:1, b:2, c:3}
    value = f.conditional(expression)
    unless value==expected
      puts expression
      puts "expected:#{expected} got:#{value}"
      puts
    end
  end
end

def compare_hashes(h1,h2)
  unless (missing = h1.keys - h2.keys).empty?
    puts "Missing keys: #{missing.join(', ')}"
  end
  unless (extra = h2.keys - h1.keys).empty?
    puts "Extra keys: #{missing.join(', ')}"
  end
  (h1.keys & h2.keys).each do |k|
    unless h1[k] == h2[k]
      puts "For #{k} expected #{h1[k].inspect} but got #{h2[k].inspect}"
    end
  end
end

def test_template
  tests = [
    { vars:{}, template:"a", expected:"a" },
    { vars:{a:17}, template:"a", expected:"a" },
    { vars:{a:17}, template:"{=a}", expected:"17" },
    { vars:{a:17}, template:"{?a}{=a}{.}", expected:"17" },
    { vars:{a:17}, template:"{? a }{=a}{.}", expected:"17" },
    { vars:{a:17}, template:"{?!a}{=a}{.}", expected:"" },
    { vars:{a:17}, template:"{?!a}{=a}{|}b{.}", expected:"b" },
    { vars:{a:1,b:2}, template:"{=a+b}", expected:"3" },
    { vars:{a:1,b:2}, template:"{=a + b}", expected:"3" },
    { vars:{a:1,b:2}, template:"{= a + b }", expected:"3" },
    { vars:{a:1,b:2}, template:"{=\na + b }", expected:"3" },
  ]

  f = Flooph.new
  tests.each do |h|
    f.vars = h[:vars]
    result = f.transform(h[:template])
    if result != h[:expected]
      puts "Variables: #{h[:vars].inspect}"
      puts "Template:  #{h[:template].inspect}"
      puts "Expected:  #{h[:expected].inspect}"
      puts "Result:    #{result.inspect}"
      puts
    end
  end
end

# $t.vars = {cats:1, dogs:2}
# <<END.split("\n").each{ |s| p s=>$t.value(s) }
# 1 + 2
# cats + 1
# cats - 1
# cats + dogs
# 1 + dogs
# 1 - dogs
# END

run!