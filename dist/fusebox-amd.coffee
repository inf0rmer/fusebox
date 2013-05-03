do ->
  exports = {}

  if window.define?.amd?
    define = window.define
  else
    exports = window
    define = (name, dependencies, fn) ->
      deps = []
      for dep in dependencies
        deps.push window[dep]

      module = fn.apply undefined, deps
      unless window[name] then window[name] = module

  define 'fusebox', ['underscore', 'jquery'], (_, $) ->
    #
    # Sandbox - Manages a whole widget (collection of modules) lifecycle.
    # Based on Bacbkone Aura (https://github.com/addyosmani/backbone-aura)
    #
    
    do ->
      root = @
      previousFusebox = @fusebox
      # Loaded modules and their callbacks
      channels = {}
      # Mediator object
      mediator = {}
      # Permissions object
      permissions = {}
      # Rules
      rules = {}
      # Base URL to fetch widgets from
      baseUrl = 'widgets/'
      # Responder cache
      responderCache = {}
    
      req = require
      reqjs = requirejs
    
      decamelize = (str, delimiter = '_') ->
        str.replace(/([A-Z])/g, delimiter + '$1').toLowerCase()
    
      permissions.extend = (extended) ->
        rules = _.extend(rules, extended)
    
      permissions.clear = ->
        rules = {}
    
      #
      # @param {string} subscriber Module name
      # @param {string} channel Event name
      #
      permissions.validate = (subscriber, channel) ->
        test = rules[channel]?[subscriber]
        if test
          return true
        else
          return false
    
      #
      # Subscribe to an event
      # @param {string} channel Event name
      # @param {object} subscription Module callback
      # @param {object} context Context in which to execute the module
      #
      mediator.subscribe = (channel, subscriber, callback, context) ->
        channels[subscriber] = if channels[subscriber]?
          channels[subscriber]
        else
          {}
    
        channels[subscriber][channel] = if channels[subscriber][channel]?
          channels[subscriber][channel]
        else
          []
    
        channels[subscriber][channel].push _.bind(callback, context)
    
    
      #
      # Unsubscribe to all events a widget has subscribed to
      # @param {string} channel Event name
      #
      mediator.unsubscribe = (channel) ->
        channels[channel] = []
    
      #
      # Publish an event, passing arguments to subscribers. Will
      # call start if the channel is not already registered.
      # @param {string} channel Event name
      #
      mediator.publish = (event, channel) ->
        args = [].slice.call(arguments, 1)
    
        return unless channels[channel]
    
        if channels[channel][event] and channels[channel][event].length
          _.each channels[channel][event], (fn) ->
            fn.apply(this, args)
    
      #
      # Start a widget, calling it's ```bootstrap``` event
      # @param {string} channel Widget name
      #
      mediator.start = (channel) ->
        args = [].slice.call(arguments, 1)
        file = decamelize(channel)
    
        # If a widget hasn't called subscribe this will fail because it won't
        # be present in the channels object
        req [baseUrl + file + "/main"], () ->
          if channels[channel]?.bootstrap?
            _.each channels[channel].bootstrap, (fn) ->
              fn.apply(mediator, args)
    
      #
      # Stop a widget, calling it's ```unload``` event
      # @param {string} channel Widget name
      #
      mediator.stop = (channel) ->
        args = [].slice.call(arguments, 1)
        el = args[0]
        file = decamelize(channel)
    
        if channels[channel]?.unload?
          mediator.publish.apply(mediator, ['unload', channel].concat(args))
    
        if el
          # Empty markup associated with the module
          $(el).html('')
    
      #
      # Undefine/unload a module, resetting the internal
      # state of it in require.js to act like it wasn't
      # loaded. By default require won't cleanup any markup
      # associated with this
      #
      # The interesting challenge with .stop() is that in
      # order to correctly clean-up one would need to maintain
      # a custom track of dependencies loaded for each
      # possible channel, including that channels DOM elements
      # per depdendency.
      #
      # This issue with this is shared dependencies.
      # E.g, say one loaded up a module
      # containing jQuery, others also use jQuery and then the
      # module was unloaded.
      # This would cause jQuery to also be unloaded if the entire
      # tree was being done so.
    
      # A simpler solution is to just remove those modules that fall
      # under the widget path as we know those dependencies
      # (e.g models, views etc) should only belong to one part of the
      # codebase and shouldn't be depended on by others.
    
      # @param {string} channel Event name
      #
      mediator.unload = (channel) ->
        contextMap = reqjs?.s.contexts._.urlMap?
    
        return unless contextMap
    
        for key in contextMap
          if contextMap.hasOwnProperty(key) and key.indexOf(channel) isnt -1
            req.undef(key)
    
      #
      # Respond to a data point with a specific callback,
      # using promises.
      #
      # @param {string} dataPoint
      # @param {function} callback
      mediator.responds = (dataPoint, callback) ->
        dfd = new $.Deferred
        responderCache[dataPoint] = () ->
          callback.call @, dfd
          return dfd
    
        return mediator
    
      #
      # Stops responding to a data point
      #
      # @param {string} dataPoint
      mediator.stopsResponding = (dataPoint) ->
        responderCache[dataPoint] = null
        delete responderCache[dataPoint]
    
        return mediator
    
      #
      # Perform a request for a data point
      #
      # @param {string} dataPoint
      mediator.request = (dataPoint) ->
        if responderCache[dataPoint]?
          dfd = responderCache[dataPoint]()
        else
          dfd = new $.Deferred
          dfd.reject()
    
        return dfd.promise()
    
      #
      # DOM Helper object for widgets
      #
      mediator.dom =
        #
        # Scoped $.find() for widgets
        # @param selector Sizzle selector to search for
        # @param context  Context to run find in. Ideally
        #                 the widget's root element.
        #
        find: (selector, context = document) ->
          $(context).find(selector)
    
        #
        # Data attribute helper
        # @param selector   Sizzle selector to search for
        # @param attribute  Data attribute to get
        #
        data: (selector, attribute) ->
          $(selector).data(attribute)
    
      #
      #  Public API
      #
      fusebox =
        #
        # Run Fusebox in noConflict mode, returing
        # the fusebox variable to its previous owner.
        # Returns a reference to the fusebox object
        #
        noConflict: ->
          root.fusebox = previousFusebox
          fusebox
    
        #
        #  @param {string} subscriber Module name
        #  @param {string} channel Event name
        #  @param {object} callback Module
        #
        subscribe: (subscriber, channel, callback) ->
          if permissions.validate(subscriber, channel)
            mediator.subscribe subscriber, channel, callback, this
    
        #
        # @param {string} subscriber Module name
        #
        publish: (subscriber) ->
          mediator.publish.apply mediator, arguments
    
        #
        #  @param {string} subscriber Module name
        #
        start: (subscriber) ->
          mediator.start.apply mediator, arguments
    
        #
        # @param {string} subscriber Module name
        #
        stop: (subscriber) ->
          mediator.stop.apply mediator, arguments
    
        #
        # @param {string} subscriber Module name
        #
        unload: (subscriber) ->
          file = decamelize(channel)
          mediator.unload.apply mediator, baseUrl + file
    
        #
        # Respond to a data point with a specific callback,
        # using promises.
        #
        # @param {string} dataPoint
        # @param {function} callback
        responds: (dataPoint, callback) ->
          mediator.responds.apply mediator, arguments
    
        #
        # Stops responding to a data point
        #
        # @param {string} dataPoint
        stopsResponding: (dataPoint) ->
          mediator.stopsResponding.apply mediator, arguments
    
        #
        # Perform a request for a data point
        #
        # @param {string} dataPoint
        request: (dataPoint) ->
          mediator.request.apply mediator, arguments
    
        #
        # @param {string} selector CSS selector for the element
        # @param {string} context CSS selector for the context in which to
        #                 search for selector
        # @returns {object} Found elements or empty array
        #
        find: (selector, context) ->
          mediator.dom.find selector, context
    
        data: (selector, attribute) ->
          mediator.dom.data selector, attribute
    
        permissions: permissions,
    
        dom: mediator.dom,
    
        setBaseUrl: (url) ->
          baseUrl = url
    
        getBaseUrl: () ->
          baseUrl
    
        setRequireLib: (reqFunc, reqGlobal) ->
          throw new Error(
            'Both a require function and a requirejs global are needed'
          ) if (arguments.length < 2)
    
          throw new Error(
            'require needs to be a function'
          ) if (typeof reqFunc isnt 'function')
    
          req = reqFunc
          reqjs = reqGlobal
    
        getRequireLib: () ->
          {
            require: req,
            requirejs: reqjs
          }
    
      # Expose fusebox
      if exports?
        if module?.exports?
          exports = module.exports = fusebox
        exports.fusebox = fusebox
      else
        root.fusebox = fusebox
    
      return fusebox