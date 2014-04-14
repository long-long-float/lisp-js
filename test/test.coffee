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
    lisp = null

    beforeEach (done) ->
      lisp = new Lisp
      done()

    it 'should return sum of arguments', ->
      expect(lisp.eval('(+ 1 2 3)')).to.equal('6')

    it 'should return first of list', ->
      expect(lisp.eval('(car \'(1 2 3)')).to.equal('1')

    it 'should return rest of list', ->
      expect(lisp.eval('cdr \'(1 2 3)')).to.equal('(2 3)')

    it 'should return joined list', ->
      expect(lisp.eval('(cons 0 \'(1 2 3)')).to.equal('(0 1 2 3)')

    it 'should return t', ->
      expect(lisp.eval('(eq 1 1)')).to.equal('t')

    it 'should return nil', ->
      expect(lisp.eval('(eq 1 2)')).to.equal('nil')

    it 'should return t', ->
      expect(lisp.eval('(atom 1)')).to.equal('t')
