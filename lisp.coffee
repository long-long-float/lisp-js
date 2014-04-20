class Atom
  constructor: (@value) ->
  toString: -> "#{@value}"

class Symbol
  constructor: (@name) ->
  toString: -> @name

class Nil extends Atom
  toString: -> 'nil'
nil = new Nil
class T extends Atom
  toString: -> 't'
t = new T

class List
  constructor: (@values) ->
  toString: -> "(#{@values.map((v) -> v.toString()).join(' ')})"

class CallFun
  constructor: (@funname, @args) ->
  toString: -> "(#{@funname} #{@values.map((v) -> v.toString()).join(' ')})"

class SpecialForm
  @NAMES = ['cond', 'quote', 'lambda', 'defun']
  constructor: (@name, @args) ->
  toString: -> "(#{@name} #{@args.map((v) -> v.toString()).join(' ')})"

class Lambda
  constructor: (@params, @body) ->

class Environment
  constructor: (@variables) ->
  get: (name) ->
    val = @variables[name]
    throw "undefined #{name}" unless val
    return val
  set: (name, val) -> @variables[name] = val

envstack = []
currentEnv = ->
  throw "envstack is empty" unless envstack.length > 0
  envstack[envstack.length - 1]

class @Parser
  constructor: ->

  skip: ->
    @pos++ while @code[@pos]?.match /[ \r\n\t]/

  isEOF: ->
    @pos == @code.length

  expects: (pattern, throwing = false) ->
    valid = @code[@pos] &&
      (pattern instanceof RegExp and pattern.test @code[@pos]) ||
      pattern == @code[@pos...@pos + pattern.length]
    if !valid && throwing
      throw "unexpected \"#{@code[@pos]}\", expects \"#{pattern}\""

    return valid

  forwards: (pattern) ->
    @expects pattern, true
    @code[@pos++]

  forwards_str: (str) ->
    @expects str, true
    @pos += str.length

  atom: ->
    #number
    if @expects /[0-9]/
      num = ''
      num += @code[@pos++] while @expects /[0-9]/
      return new Atom(parseInt(num))

    #string
    if @expects '"'
      @forwards '"'
      str = ''
      str += @code[@pos++] until @expects '"'
      @forwards '"'
      return new Atom(str)

    #nil
    if @expects 'nil'
      @forwards_str 'nil'
      return nil

    #t
    if @expects 't'
      @forwards 't'
      return t

    #var
    return new Symbol(@symbol())

  symbol: ->
    ret = ''
    ret += @code[@pos++] while @expects /[\w!#$%&=-~^|*+<>?_]/
    return ret

  list: ->
    @forwards '('
    values = []
    until @expects(')') or @isEOF()
      values.push @expr()
      @skip()
    @forwards ')'
    return new List(values)

  call_fun: ->
    @forwards '('
    args = []
    funname = @expr()

    isSF = SpecialForm.NAMES.indexOf(funname.name) != -1
    until @expects(')') or @isEOF()
      @skip()
      args.push @expr(isSF)

    @forwards ')'

    klass = if isSF then SpecialForm else CallFun
    return new klass(funname, args)

  expr: (isSF) ->
    if @expects("'") or isSF #value
      @forwards "'" unless isSF
      if @expects '(' #list
        return @list()
      else #atom
        return @atom()
    else if @expects '(' #calling function or special form
      return @call_fun()
    else #atom
      return @atom()

  program: ->
    ret = []
    until @isEOF()
      @skip()
      ret.push @expr()
    return ret

  parse: (@code) ->
    @pos = 0
    @program()

class Evaluator
  constructor: ->

  exec_lambda: (lambda, args) ->
    envstack.push new Environment(lambda.params.values.reduce(
      ((env, param, index) -> env[param.name] = args[index]; env), {}))
    [name, args...] = lambda.body.values
    ret = @eval_expr(new CallFun(name, args)) #とりあえず
    envstack.pop()
    return ret

  eval_expr: (expr) ->
    switch expr.constructor.name
      when 'SpecialForm'
        args = expr.args
        switch expr.name.name
          when 'cond'
            ret = args.filter((arg) => !(@eval_expr(arg.values[0]) instanceof Nil))[0]?.values[1] || nil
          when 'quote'
            args[0]
          when 'lambda'
            new Lambda(args[0], args[1])
          when 'defun'
            lambda = new Lambda(args[1], args[2])
            currentEnv().set(args[0].name, lambda)
            return lambda

      when 'CallFun'
        args = expr.args.map (arg) => @eval_expr(arg)
        funname = if expr.funname instanceof SpecialForm then @eval_expr(expr.funname) else expr.funname
        switch funname.constructor.name
          when 'Lambda'
            @exec_lambda(funname)
          when 'Symbol'
            switch funname.name
              when 'alert'
                alert args[0].value
                nil
              when '+'
                new Atom args.reduce(((sum, n) -> sum + n.value), 0)
              when 'car'
                args[0].values[0]
              when 'cdr'
                new List args[0].values[1..]
              when 'cons'
                newList = args[1].values[..]
                newList.unshift(args[0])
                new List newList
              when 'eq'
                if args[0].value == args[1].value then t else nil
              when 'atom'
                if args[0] instanceof Atom then t else nil
              else
                lambda = currentEnv().get(funname.name)
                if lambda
                  @exec_lambda(lambda, args)
                else
                  throw "undefined function : #{funname.name}"
          else
            throw "#{JSON.stringify(funname)}(#{funname.constructor.name}) is not a function"
      when 'Symbol'
        currentEnv().get(expr.name)
      else
        expr

  eval: (ast) ->
    ret = nil
    envstack.push new Environment({})
    for expr in ast
      ret = @eval_expr(expr)
    return ret.toString()

class @Lisp
  @eval: (code) ->
    ast = (new Parser).parse(code)
    {ast: ast, body: (new Evaluator).eval(ast)}

#support script tag
$ ->
  $('script[type="text/lisp"]').each ->
    Lisp.eval $(this).text()