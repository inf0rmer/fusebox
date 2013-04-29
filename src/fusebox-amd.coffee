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
    #= ./fusebox.coffee