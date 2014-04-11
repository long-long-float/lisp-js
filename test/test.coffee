describe 'Lisp', ->
  describe 'parser', ->
    it 'should not thrown', ->
      expect -> (new Parser).parse('(1 "hoge" nil t \'(1 2 3))')
        .not.to.throw()
      expect -> (new Parser).parse('(cons 0 \'(1 2 3))')
        .not.to.throw()
      expect -> (new Parser).parse('(cond ((eq 1 1) "hoge") ((eq 2 2) "piyo"))')
        .not.to.throw()
      expect -> (new Parser).parse('(quote (1 2 3))')
        .not.to.throw()
    it 'should thrown', ->
      expect -> (new Parser).parse('(')
        .to.throw()