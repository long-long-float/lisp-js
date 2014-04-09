class Atom
  constructor: (@value) ->

class Nil extends Atom

class List
  constructor: (@values, @as_data) ->

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

  list: (as_data) ->
    @forwards '('
    ret = []
    until @expects ')', false
      ret.push @expr()
      @skip()
    @forwards ')'
    return new List(ret, as_data)

  expr: ->
    if @expects "'", false #value
      @forwards "'"
      return @list(true)
    else if @expects '(', false #calling function
      return @list(false)
    else #atom
      return @atom()

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