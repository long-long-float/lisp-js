merge = ->
  args = Array.prototype.slice.call(arguments)

  ret = {}
  for arg in args
    for item of arg
      if arg.hasOwnProperty(item)
        ret[item] = arg[item]

  return ret

class Atom
  constructor: (@value) ->

class Nil extends Atom

class List
  constructor: (@values, @as_data) ->

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

  eval: (ast) ->
    


class @Lisp
  @eval: (code, opts) ->
    opts = merge(ast: false, opts)
    ast = (new Parser).parse(code)
    ret = {}
    ret.ast = ast if opts.ast
    ret.body = (new Evaluator).eval(ast)
    
    return ret