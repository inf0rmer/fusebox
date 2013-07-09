Sandbox = require 'fusebox'
originalLib = Sandbox.getRequireLib()

describe 'Sandbox', ->

  beforeEach ->
    Sandbox.permissions.clear()
    Sandbox.setBaseUrl('widgets/')
    Sandbox.setRequireLib(originalLib.require, originalLib.requirejs)
    $('.my-widget').remove()

  describe 'baseUrl', ->

    it 'has a default baseUrl with value "widgets/"', ->
      expect(Sandbox.getBaseUrl()).toBe('widgets/')

    it 'can set a different baseUrl', ->
      Sandbox.setBaseUrl('shenanigans/')
      expect(Sandbox.getBaseUrl()).toBe('shenanigans/')

  describe 'requireLib', ->

    it 'has a default loader library', ->
      expect(Sandbox.getRequireLib()).toBeDefined()
      expect(Sandbox.getRequireLib().require).toBe(require)
      expect(Sandbox.getRequireLib().requirejs).toBe(requirejs)

    it 'can set a new loader library', ->
      done = 0
      dummyReq = () ->
        done++
      dummyReqjs = () ->
        done++

      Sandbox.setRequireLib dummyReq, dummyReqjs

      lib = Sandbox.getRequireLib()
      lib.require()
      lib.requirejs()

      expect(done).toBe(2)

    it 'throws an Error when setRequireLib receives less than 2 params', ->
      fn = () ->
        return

      expect(Sandbox.setRequireLib).toThrow(
        new Error('Both a require function and a requirejs global are needed')
      )
      expect( ()->
        Sandbox.setRequireLib(fn)
      ).toThrow(
        new Error('Both a require function and a requirejs global are needed')
      )

    it 'throws an Error when setRequireLib receives a non-function as a first param', ->
      expect( ()->
        Sandbox.setRequireLib('a-string', {obj: 'obj'})
      ).toThrow(new Error('require needs to be a function'))


  describe 'Permissions', ->

    it 'can set permissions for a widget', ->

      rules = Sandbox.permissions.extend
        "my-widget":
          bootstrap: true

      expect(rules['my-widget'].bootstrap).toBe(true)

    it 'can validate permissions for a widget', ->

      Sandbox.permissions.extend
        "my-widget":
          bootstrap: true

      expect(Sandbox.permissions.validate('bootstrap', 'my-widget')).toBe(true)

  describe 'Pub/Sub', ->

    it 'can subscribe to a widget event and publish it', ->
      done = false

      Sandbox.permissions.extend
        "my-widget":
          apocalypse: true

      Sandbox.subscribe 'apocalypse', 'my-widget', () ->
        done = true

      Sandbox.publish 'apocalypse', 'my-widget'

      expect(done).toBe(true)

    it 'can unsubscribe from all of a widget\'s events', ->

      Sandbox.permissions.extend
        "my-widget":
          apocalypse: true

      spy = jasmine.createSpy()
      Sandbox.subscribe 'apocalypse', 'my-widget', spy

      Sandbox.unsubscribe 'my-widget'
      Sandbox.publish 'apocalypse', 'my-widget'
      expect(spy).not.toHaveBeenCalled()

  describe 'Lifecycle', ->

    it 'can start a widget', ->
      done = false

      Sandbox.permissions.extend
        "my-widget":
          bootstrap: true

      req = (file, callback) ->
        callback.call()

      Sandbox.setRequireLib req, requirejs

      Sandbox.subscribe 'bootstrap', 'my-widget', ->
        done = true

      Sandbox.start('my-widget', 'body')

      expect(done).toBe(true)

    it 'can stop a widget', ->
      done = false

      Sandbox.permissions.extend
        "my-widget":
          unload: true

      req = (file, callback) ->
        callback.call()

      Sandbox.setRequireLib req, requirejs

      Sandbox.subscribe 'unload', 'my-widget', ->
        done = true

      Sandbox.stop('my-widget')

      expect(done).toBe(true)

    it "clears the widget's element upon stopping it", ->

      $('body').append('<div class="my-widget">Some text</div>')

      Sandbox.permissions.extend
        "my-widget":
          unload: true

      req = (file, callback) ->
        callback.call()

      Sandbox.setRequireLib req, requirejs

      Sandbox.stop('my-widget', '.my-widget')

      expect($('.my-widget').html()).toBe('')

  describe 'Data Responders', ->

    it 'allows chaining when responding to a data point', ->
      mediator = Sandbox.responds "my:data:point", (dfd) ->
        dfd.resolve(true)

      expect(mediator.responds).toBeDefined()

    it 'allows chaining when relinquishing response to a data point', ->
      Sandbox.responds "my:data:point", (dfd) ->
        dfd.resolve(true)

      mediator = Sandbox.stopsResponding 'my:data:point'

      expect(mediator.responds).toBeDefined()

    it 'can request a data point', ->
      done = false

      Sandbox.responds "my:data:point", (dfd) ->
        dfd.resolve(true)

      runs ->
        promise = Sandbox.request "my:data:point"
        promise.done (val) ->
          done = val
          expect(done).toBeTruthy()

      waitsFor ->
        done

    it 'can pass arguments to a request for a data point', ->
      done = false

      Sandbox.responds "my:data:point", (dfd, value) ->
        dfd.resolve(value)

      runs ->
        promise = Sandbox.request "my:data:point", true
        promise.done (val) ->
          done = val
          expect(done).toBeTruthy()

      waitsFor ->
        done

    it 'can stop responding to a data point', ->
      done = false

      Sandbox.responds "my:data:point", (dfd) ->
        dfd.resolve(true)

      Sandbox.stopsResponding "my:data:point"

      runs ->
        promise = Sandbox.request "my:data:point"
        promise.fail ->
          done = true
          expect(done).toBeTruthy()

      waitsFor ->
        done
