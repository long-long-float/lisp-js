class Symbol
  constructor: (@name, @pos) ->
  toString: -> @name

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
  toString: -> "(#{@funname} #{@values.map((v) -> v.toString()).join(' ')})"

SF_NAMES = ['cond', 'quote', 'lambda', 'defun']
class SpecialForm
  constructor: (@name, @args) ->
  toString: -> "(#{@name} #{@args.map((v) -> v.toString()).join(' ')})"

class Lambda
  constructor: (@params, @body) ->

class Environment
  constructor: (@variables) ->
  get: (name) -> @variables[name]
  set: (name, val) -> @variables[name] = val

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
  throw new klass("#{msg} at #{pos.row}:#{pos.column}")

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

  atom: ->
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
    return new Symbol(@symbol(), @currentPos())

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

    isSF = SF_NAMES.indexOf(funname.name) != -1
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
        {
          'cond': =>
            for arg in args
              unless @eval_expr(arg.values[0]) instanceof Nil
                return arg.values[1]
            return nil
          'quote': ->
            args[0]
          'lambda': ->
            new Lambda(args[0], args[1])
          'defun': ->
            currentEnv().set(args[0].name, new Lambda(args[1], args[2]))
        }[expr.name.name]()

      when 'CallFun'
        args = expr.args.map (arg) => @eval_expr(arg)
        funname = if expr.funname instanceof SpecialForm then @eval_expr(expr.funname) else expr.funname
        switch funname.constructor.name
          when 'Lambda'
            @exec_lambda(funname)
          when 'Symbol'
            funcs = {
              '+': -> args.reduce(((sum, n) -> sum + n), 0),
              'car': -> args[0].values[0]
              'cdr': -> new List args[0].values[1..]
              'cons': -> new List [args[0], args[1].values...]
              'eq': -> if args[0] == args[1] then t else nil
              'atom': -> if isAtom(args[0]) then t else nil
            }
            if funs = funcs[funname.name]
              funs()
            else
              if lambda = currentEnv().get(funname.name)
                @exec_lambda(lambda, args)
              else
                error NameError, "undefined function \"#{funname.name}\"", funname.pos
          else
            error NotFunctionError, "#{JSON.stringify(funname)}(#{funname.constructor.name}) is not a function", funname.pos
      when 'Symbol'
        currentEnv().get(expr.name)
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
