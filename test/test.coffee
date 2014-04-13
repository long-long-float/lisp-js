describe 'Lisp', ->
  describe 'parser', ->
    p = null

    beforeEach (done) ->
      p = new Parser
      done()

    it 'should not thrown', ->
      expect -> p.parse('(1 "hoge" nil t \'(1 2 3))')
        .not.to.throw()
      expect -> p.parse('(cons 0 \'(1 2 3))')
        .not.to.throw()
      expect -> p.parse('(cond ((eq 1 1) "hoge") ((eq 2 2) "piyo"))')
        .not.to.throw()
      expect -> p.parse('(quote (1 2 3))')
        .not.to.throw()
      expect -> p.parse('(lambda (x y) (+ x y))')
        .not.to.throw()
    it 'should thrown', ->
      expect -> p.parse('(').to.throw()