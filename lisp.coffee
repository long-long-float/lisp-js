class Atom
  constructor: (@value) ->

class List
  constructor: (@values) ->

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
      throw "unexpected #{@getChar()}, expects #{pattern}"

    return valid

  forwards: (pattern) ->
    @expects pattern
    @pos++

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

  list: ->
    @forwards '('
    ret = []
    until @expects ')', false
      ret.push @atom()
      @skip()
    @forwards ')'
    return new List(ret)

  program: ->
    ret = []
    ret.push @list() until @isEOF()
    return ret

  parse: (@code) ->
    @pos = 0
    @program()

class @Lisp
  @eval: (code) ->
    p = new Parser
    p.parse(code)