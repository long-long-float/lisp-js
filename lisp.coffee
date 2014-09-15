class Symbol
  constructor: (@name, @quoted, @pos) ->
  toString: -> "#{if @quoted then "'" else ""}#{@name}"

class Nil
  toString: -> 'nil'
nil = new Nil
class T
  toString: -> 't'
t = new T

class List
  constructor: (@values) ->
  toString: -> "(#{@values.map((v) -> v.toString()).join(' ')})"

class CallFun
  constructor: (@funname, @args) ->
    @values = [@funname, @args...]
  toString: -> "(#{@values.map((v) -> v.toString()).join(' ')})"

class Lambda
  constructor: (@params, @exprs) ->

class Environment
  constructor: (@variables) ->
    @macros = {}
  get: (name)      -> @variables[name]
  set: (name, val) -> @variables[name] = val
  getMacro: (name)        -> @macros[name]
  setMacro: (name, macro) -> @macros[name] = macro

class LispError extends Error
  constructor: (@message) ->
    @name = @constructor.name
  toString: -> "[object: #{@name}]"

class ParseError extends LispError

class NameError extends LispError

class NotFunctionError extends LispError

isAtom = (val) ->
  typeof val == 'string' or typeof val == 'number' or
    val instanceof Nil or val instanceof T

envstack = []
currentEnv = ->
  throw "envstack is empty" unless envstack.length > 0
  envstack[envstack.length - 1]

error = (klass, msg, pos) ->
  throw new klass("#{msg}" + if pos? then " at #{pos.row}:#{pos.column}" else "")

SYMBOL_PATTERN = /[\w+\-*/!#$%&=~^|<>?_]/

class @Parser
  skip: ->
    @pos++ while @code[@pos]?.match /[ \r\n\t]/

  isEOF: ->
    @pos == @code.length

  currentPos: ->
    headToCurrent = @code.substr(0, @pos)
    {
      row: headToCurrent.split("\n").length
      column: @pos - headToCurrent.lastIndexOf("\n") - 1
    }

  expects: (pattern, throwing = false) ->
    valid = @code[@pos] && (pattern instanceof RegExp and pattern.test @code[@pos]) || pattern == @code[@pos...@pos + pattern.length]
    if !valid && throwing
      token = if @isEOF() then 'EOF' else @code[@pos]
      error ParseError, "unexpected \"#{token}\", expects \"#{pattern}\"", @currentPos()

    return valid

  forwards: (pattern) ->
    @expects pattern, true
    @code[@pos]
    @pos += if pattern instanceof RegExp then 1 else pattern.length

  forwards_if: (pattern) ->
    @forwards pattern if @expects pattern

  atom: (quoted) ->
    #number
    if @expects /[0-9]/
      num = ''
      num += @code[@pos++] while @expects /[0-9]/
      return parseInt(num)

    #string
    if @forwards_if '"'
      str = ''
      str += @code[@pos++] until @expects '"'
      @forwards '"'
      return str

    return nil if @forwards_if 'nil'
    return t if @forwards_if 't'

    #var
    return new Symbol(@symbol(), quoted, @currentPos())

  symbol: ->
    ret = ''
    ret += @code[@pos++] while @expects SYMBOL_PATTERN
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

    until @expects(')') or @isEOF()
      @skip()
      args.push @expr()

    @forwards ')'

    return new CallFun(funname, args)

  expr:  ->
    if @expects("'") #value
      @forwards "'"
      if @expects '(' #list
        return @list()
      else #quoted atom
        return @atom(true)
    else if @expects '(' #calling function
      return @call_fun()
    else #atom
      return @atom(false)

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
  exec_lambda: (lambda, args) ->
    envstack.push new Environment(lambda.params.values.reduce(
      ((env, param, index) -> env[param.name] = args[index]; env), {}))
    ret = lambda.exprs.map((expr) =>
      @eval_expr(expr))[0]
    envstack.pop()
    return ret

  eval_expr: (expr) ->
    switch expr.constructor.name
      when 'CallFun'
        args = expr.args

        SPECIAL_FORMS = {
          'cond': =>
            for arg in args
              unless @eval_expr(arg.values[0]) instanceof Nil
                return arg.values[1]
            return nil
          'quote': ->
            args[0]
          'lambda': ->
            new Lambda(args[0], args[1..])
          'defun': ->
            currentEnv().set(args[0].name, new Lambda(args[1], args[2..]))
          'setq': =>
            value = @eval_expr(args[1])
            currentEnv().set(args[0].name, value)
          'defmacro': ->
            currentEnv().setMacro(args[0].name, new Lambda(args[1], args[2..]))
          'let': =>
            @exec_lambda(
              new Lambda(new List(args[0].values.map((pair) -> pair.values[0])), args[1..]),
              args[0].values.map((pair) -> pair.values[1]))
        }

        funname = expr.funname

        if sf = SPECIAL_FORMS[funname.name]
          return sf(expr.args)

        args = unless currentEnv().getMacro(funname.name)
              expr.args.map (arg) => @eval_expr(arg)
            else
              expr.args
        switch funname.constructor.name
          when 'Lambda'
            @exec_lambda(funname)
          when 'Symbol'
            funcs = {
              'list': ->
                [name, args...] = args
                new CallFun name, args
              '+': -> args.reduce(((sum, n) -> sum + n), 0)
              '-': -> args[1..].reduce(((sub, n) -> sub - n), args[0]) # Array#reduce includes first value
              '*': -> args.reduce(((mul, n) -> mul * n), 1)
              '/': -> args[1..].reduce(((div, n) -> div / n), args[0])
              'car': -> args[0].values[0]
              'cdr': -> new List args[0].values[1..]
              'cons': -> new List [args[0], args[1].values...]
              'eq': -> if args[0] == args[1] then t else nil
              'atom': -> if isAtom(args[0]) then t else nil
            }
            if funs = funcs[funname.name]
              funs()
            else
              if macro = currentEnv().getMacro(funname.name)
                expr = @exec_lambda(macro, args)
                @eval_expr(expr)
              else if lambda = currentEnv().get(funname.name)
                @exec_lambda(lambda, args)
              else
                error NameError, "undefined function \"#{funname.name}\"", funname.pos
          else
            error NotFunctionError, "#{funname.toString()}(#{funname.constructor.name}) is not a function", funname.pos
      when 'Symbol'
        if expr.quoted
          return expr

        value = currentEnv().get(expr.name)
        unless value
          error NameError, "undefined valiable \"#{expr.name}\"", expr.pos
        value
      else
        expr

  eval: (ast) ->
    envstack.push new Environment({})
    return (@eval_expr(expr) for expr in ast).pop().toString()

class @Lisp
  @eval: (code) ->
    ast = (new Parser).parse(code)
    {ast: ast, body: (new Evaluator).eval(ast)}

#support script tag
if $?
  $ ->
    $('script[type="text/lisp"]').each ->
      Lisp.eval $(this).text()
