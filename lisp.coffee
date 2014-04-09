class Atom
  constructor: (@value) ->

class Item
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
    num = ''
    while @expects /[0-9]/, false
      num += @getChar()
      @pos++
    return new Atom(num)

  item: ->
    return new Item(@atom())

  list: ->
    @forwards '('
    ret = []
    until @expects ')', false
      ret.push @item()
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