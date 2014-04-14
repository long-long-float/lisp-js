// Generated by CoffeeScript 1.7.1
(function() {
  describe('Lisp', function() {
    describe('parser', function() {
      var p;
      p = null;
      beforeEach(function(done) {
        p = new Parser;
        return done();
      });
      it('should not thrown', function() {
        expect(function() {
          return p.parse('(1 "hoge" nil t \'(1 2 3))');
        }).not.to["throw"]();
        expect(function() {
          return p.parse('(cons 0 \'(1 2 3))');
        }).not.to["throw"]();
        expect(function() {
          return p.parse('(cond ((eq 1 1) "hoge") ((eq 2 2) "piyo"))');
        }).not.to["throw"]();
        expect(function() {
          return p.parse('(quote (1 2 3))');
        }).not.to["throw"]();
        return expect(function() {
          return p.parse('(lambda (x y) (+ x y))');
        }).not.to["throw"]();
      });
      return it('should thrown', function() {
        return expect(function() {
          return p.parse('(').to["throw"]();
        });
      });
    });
    return describe('evaluator', function() {
      var lisp;
      lisp = null;
      beforeEach(function(done) {
        lisp = new Lisp;
        return done();
      });
      it('should return sum of arguments', function() {
        return expect(lisp["eval"]('(+ 1 2 3)')).to.equal('6');
      });
      it('should return first of list', function() {
        return expect(lisp["eval"]('(car \'(1 2 3)')).to.equal('1');
      });
      it('should return rest of list', function() {
        return expect(lisp["eval"]('cdr \'(1 2 3)')).to.equal('(2 3)');
      });
      it('should return joined list', function() {
        return expect(lisp["eval"]('(cons 0 \'(1 2 3)')).to.equal('(0 1 2 3)');
      });
      it('should return t', function() {
        return expect(lisp["eval"]('(eq 1 1)')).to.equal('t');
      });
      it('should return nil', function() {
        return expect(lisp["eval"]('(eq 1 2)')).to.equal('nil');
      });
      return it('should return t', function() {
        return expect(lisp["eval"]('(atom 1)')).to.equal('t');
      });
    });
  });

}).call(this);
