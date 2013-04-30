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
      return it('can subscribe to a widget event and publish it', function() {
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
    });
    return describe('Lifecycle', function() {
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
  });

}).call(this);
