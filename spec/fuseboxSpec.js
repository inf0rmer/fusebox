(function() {
  var Sandbox, originalLib;

  Sandbox = require('fusebox');

  originalLib = Sandbox.getRequireLib();

  describe('Sandbox', function() {
    beforeEach(function() {
      Sandbox.permissions.clear();
      Sandbox.setBaseUrl('widgets/');
      Sandbox.setRequireLib(originalLib.require, originalLib.requirejs);
      return $('.my-widget').remove();
    });
    describe('baseUrl', function() {
      it('has a default baseUrl with value "widgets/"', function() {
        return expect(Sandbox.getBaseUrl()).toBe('widgets/');
      });
      return it('can set a different baseUrl', function() {
        Sandbox.setBaseUrl('shenanigans/');
        return expect(Sandbox.getBaseUrl()).toBe('shenanigans/');
      });
    });
    describe('requireLib', function() {
      it('has a default loader library', function() {
        expect(Sandbox.getRequireLib()).toBeDefined();
        expect(Sandbox.getRequireLib().require).toBe(require);
        return expect(Sandbox.getRequireLib().requirejs).toBe(requirejs);
      });
      it('can set a new loader library', function() {
        var done, dummyReq, dummyReqjs, lib;

        done = 0;
        dummyReq = function() {
          return done++;
        };
        dummyReqjs = function() {
          return done++;
        };
        Sandbox.setRequireLib(dummyReq, dummyReqjs);
        lib = Sandbox.getRequireLib();
        lib.require();
        lib.requirejs();
        return expect(done).toBe(2);
      });
      it('throws an Error when setRequireLib receives less than 2 params', function() {
        var fn;

        fn = function() {};
        expect(Sandbox.setRequireLib).toThrow(new Error('Both a require function and a requirejs global are needed'));
        return expect(function() {
          return Sandbox.setRequireLib(fn);
        }).toThrow(new Error('Both a require function and a requirejs global are needed'));
      });
      return it('throws an Error when setRequireLib receives a non-function as a first param', function() {
        return expect(function() {
          return Sandbox.setRequireLib('a-string', {
            obj: 'obj'
          });
        }).toThrow(new Error('require needs to be a function'));
      });
    });
    describe('Permissions', function() {
      it('can set permissions for a widget', function() {
        var rules;

        rules = Sandbox.permissions.extend({
          "my-widget": {
            bootstrap: true
          }
        });
        return expect(rules['my-widget'].bootstrap).toBe(true);
      });
      return it('can validate permissions for a widget', function() {
        Sandbox.permissions.extend({
          "my-widget": {
            bootstrap: true
          }
        });
        return expect(Sandbox.permissions.validate('bootstrap', 'my-widget')).toBe(true);
      });
    });
    describe('Pub/Sub', function() {
      it('can subscribe to a widget event and publish it', function() {
        var done;

        done = false;
        Sandbox.permissions.extend({
          "my-widget": {
            apocalypse: true
          }
        });
        Sandbox.subscribe('apocalypse', 'my-widget', function() {
          return done = true;
        });
        Sandbox.publish('apocalypse', 'my-widget');
        return expect(done).toBe(true);
      });
      return it('can unsubscribe from all of a widget\'s events', function() {
        var spy;

        Sandbox.permissions.extend({
          "my-widget": {
            apocalypse: true
          }
        });
        spy = jasmine.createSpy();
        Sandbox.subscribe('apocalypse', 'my-widget', spy);
        Sandbox.unsubscribe('my-widget');
        Sandbox.publish('apocalypse', 'my-widget');
        return expect(spy).not.toHaveBeenCalled();
      });
    });
    describe('Lifecycle', function() {
      it('can start a widget', function() {
        var done, req;

        done = false;
        Sandbox.permissions.extend({
          "my-widget": {
            bootstrap: true
          }
        });
        req = function(file, callback) {
          return callback.call();
        };
        Sandbox.setRequireLib(req, requirejs);
        Sandbox.subscribe('bootstrap', 'my-widget', function() {
          return done = true;
        });
        Sandbox.start('my-widget', 'body');
        return expect(done).toBe(true);
      });
      it('can stop a widget', function() {
        var done, req;

        done = false;
        Sandbox.permissions.extend({
          "my-widget": {
            unload: true
          }
        });
        req = function(file, callback) {
          return callback.call();
        };
        Sandbox.setRequireLib(req, requirejs);
        Sandbox.subscribe('unload', 'my-widget', function() {
          return done = true;
        });
        Sandbox.stop('my-widget');
        return expect(done).toBe(true);
      });
      return it("clears the widget's element upon stopping it", function() {
        var req;

        $('body').append('<div class="my-widget">Some text</div>');
        Sandbox.permissions.extend({
          "my-widget": {
            unload: true
          }
        });
        req = function(file, callback) {
          return callback.call();
        };
        Sandbox.setRequireLib(req, requirejs);
        Sandbox.stop('my-widget', '.my-widget');
        return expect($('.my-widget').html()).toBe('');
      });
    });
    return describe('Data Responders', function() {
      it('allows chaining when responding to a data point', function() {
        var mediator;

        mediator = Sandbox.responds("my:data:point", function(dfd) {
          return dfd.resolve(true);
        });
        return expect(mediator.responds).toBeDefined();
      });
      it('allows chaining when relinquishing response to a data point', function() {
        var mediator;

        Sandbox.responds("my:data:point", function(dfd) {
          return dfd.resolve(true);
        });
        mediator = Sandbox.stopsResponding('my:data:point');
        return expect(mediator.responds).toBeDefined();
      });
      it('can request a data point', function() {
        var done;

        done = false;
        Sandbox.responds("my:data:point", function(dfd) {
          return dfd.resolve(true);
        });
        runs(function() {
          var promise;

          promise = Sandbox.request("my:data:point");
          return promise.done(function(val) {
            done = val;
            return expect(done).toBeTruthy();
          });
        });
        return waitsFor(function() {
          return done;
        });
      });
      it('can pass arguments to a request for a data point', function() {
        var done;

        done = false;
        Sandbox.responds("my:data:point", function(dfd, value) {
          return dfd.resolve(value);
        });
        runs(function() {
          var promise;

          promise = Sandbox.request("my:data:point", true);
          return promise.done(function(val) {
            done = val;
            return expect(done).toBeTruthy();
          });
        });
        return waitsFor(function() {
          return done;
        });
      });
      return it('can stop responding to a data point', function() {
        var done;

        done = false;
        Sandbox.responds("my:data:point", function(dfd) {
          return dfd.resolve(true);
        });
        Sandbox.stopsResponding("my:data:point");
        runs(function() {
          var promise;

          promise = Sandbox.request("my:data:point");
          return promise.fail(function() {
            done = true;
            return expect(done).toBeTruthy();
          });
        });
        return waitsFor(function() {
          return done;
        });
      });
    });
  });

}).call(this);
