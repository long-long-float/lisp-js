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

  describe 'evaluator', ->
    it 'should return sum of arguments', ->
      expect(Lisp.eval('(+ 1 2 3)').body).to.equal('6')

    it 'should return first of list', ->
      expect(Lisp.eval('(car \'(1 2 3))').body).to.equal('1')

    it 'should return rest of list', ->
      expect(Lisp.eval('(cdr \'(1 2 3))').body).to.equal('(2 3)')

    it 'should return joined list', ->
      expect(Lisp.eval('(cons 0 \'(1 2 3))').body).to.equal('(0 1 2 3)')

    it 'should return t', ->
      expect(Lisp.eval('(eq 1 1)').body).to.equal('t')

    it 'should return nil', ->
      expect(Lisp.eval('(eq 1 2)').body).to.equal('nil')

    it 'should return t', ->
      expect(Lisp.eval('(atom 1)').body).to.equal('t')
