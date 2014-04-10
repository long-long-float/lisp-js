merge = ->
  args = Array::slice.call(arguments)

  ret = {}
  for arg in args
    for item of arg
      if arg.hasOwnProperty(item)
        ret[item] = arg[item]

  return ret

class Atom
  constructor: (@value) ->

class Nil extends Atom

class T extends Atom

class List
  constructor: (@values) ->

class CallFun
  constructor: (@funname, @args) ->

class Parser
  constructor: ->

  getChar: -> @code[@pos]

  skip: ->
    @pos++ while @getChar()?.match /[ ]/

  isEOF: ->
    @pos == @code.length

  expects: (pattern, throwing = true) ->
    valid = (pattern instanceof RegExp and pattern.test @getChar()) || pattern == @getChar()
    if !valid && throwing
      throw "unexpected \"#{@getChar()}\", expects \"#{pattern}\""

    return valid

  expects_str: (str, throwing = true) ->
    valid = @code[@pos...@pos + str.length] == str

  forwards: (pattern) ->
    @expects pattern
    @pos++

  forwards_str: (str) ->
    @expects_str str
    @pos += str.length

  atom: ->
    c = @getChar()

    #number
    if @expects /[0-9]/, false
      num = ''
      while @expects /[0-9]/, false
        num += @getChar()
        @pos++
      return new Atom(parseInt(num))

    #string
    if @expects '"', false
      @forwards '"'
      str = ''
      until @expects '"', false
        str += @getChar()
        @pos++
      @forwards '"'
      return new Atom(str)

    #nil
    if @expects_str 'nil', false
      @forwards_str 'nil'
      return new Nil

    #t
    if @expects 't', false
      @forwards 't'
      return new T

  fun_name: ->
    ret = ''
    while @expects /[\w!#$%&=-~^|*+<>?_]/, false
      ret += @getChar()
      @pos++
    return ret

  list: ->
    @forwards '('
    values = []
    until @expects ')', false
      values.push @expr()
      @skip()
    @forwards ')'
    return new List(values)

  call_fun: ->
    @forwards '('
    args = []
    funname = @fun_name()
    until @expects ')', false
      @skip()
      args.push @expr()
    @forwards ')'
    return new CallFun(funname, args)

  expr: ->
    if @expects "'", false #value
      @forwards "'"
      if @expects '(', false #list
        return @list()
      else #atom
        return @atom()
    else if @expects '(', false #calling function
      return @call_fun()
    else #atom
      return @atom()

  program: ->
    ret = []
    ret.push @expr() until @isEOF()
    return ret

  parse: (@code) ->
    @pos = 0
    @program()

class Evaluator
  constructor: ->

  eval_expr: (expr) ->
    console.log expr
    switch expr.constructor.name
      when 'CallFun'
        args = expr.args
        switch expr.funname
          when '+'
            new Atom args.reduce(((sum, n) -> sum + n.value), 0)
          when 'car'
            new List args[0].values[0]
          when 'cdr'
            new List args[0].values[1..]
          when 'cons'
            newList = args[1].values[..]
            newList.unshift(args[0])
            new List newList
          when 'eq'
            if args[0].value == args[1].value then new T else new Nil
          when 'atom'
            if args[0] instanceof Atom then new T else new Nil
      else
        expr

  eval: (ast) ->
    for expr in ast
      @eval_expr(expr)

class @Lisp
  @eval: (code, opts) ->
    opts = merge(ast: false, opts)
    ast = (new Parser).parse(code)
    ret = {}
    ret.ast = ast if opts.ast
    ret.body = (new Evaluator).eval(ast)
    
    return ret