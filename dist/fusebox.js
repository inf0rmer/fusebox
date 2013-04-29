(function() {
  var baseUrl, channels, decamelize, exports, fusebox, mediator, permissions, previousFusebox, root, rules;

  root = this;
  previousFusebox = this.fusebox;
  channels = {};
  mediator = {};
  permissions = {};
  rules = {};
  baseUrl = 'widgets/';
  decamelize = function(str, delimiter) {
    if (delimiter == null) {
      delimiter = '_';
    }
    return str.replace(/([A-Z])/g, delimiter + '$1').toLowerCase();
  };
  permissions.extend = function(extended) {
    return rules = _.extend(rules, extended);
  };
  permissions.clear = function() {
    return rules = {};
  };
  permissions.validate = function(subscriber, channel) {
    var test, _ref;

    test = (_ref = rules[channel]) != null ? _ref[subscriber] : void 0;
    if (test) {
      return true;
    } else {
      return false;
    }
  };
  mediator.subscribe = function(channel, subscriber, callback, context) {
    channels[subscriber] = channels[subscriber] != null ? channels[subscriber] : {};
    channels[subscriber][channel] = channels[subscriber][channel] != null ? channels[subscriber][channel] : [];
    return channels[subscriber][channel].push(_.bind(callback, context));
  };
  mediator.unsubscribe = function(channel) {
    return channels[channel] = [];
  };
  mediator.publish = function(event, channel) {
    var args;

    args = [].slice.call(arguments, 1);
    if (!channels[channel]) {
      return;
    }
    if (channels[channel][event] && channels[channel][event].length) {
      return _.each(channels[channel][event], function(fn) {
        return fn.apply(this, args);
      });
    }
  };
  mediator.start = function(channel) {
    var args, file;

    args = [].slice.call(arguments, 1);
    file = decamelize(channel);
    return req([baseUrl + file + "/main"], function() {
      return _.each(channels[channel].bootstrap, function(fn) {
        return fn.apply(mediator, args);
      });
    });
  };
  mediator.stop = function(channel) {
    var args, el, file;

    args = [].slice.call(arguments, 1);
    el = args[0];
    file = decamelize(channel);
    mediator.publish.apply(mediator, ['unload', channel].concat(args));
    if (el) {
      return $(el).html('');
    }
  };
  mediator.unload = function(channel) {
    var contextMap, key, _i, _len, _results;

    contextMap = (typeof reqjs !== "undefined" && reqjs !== null ? reqjs.s.contexts._.urlMap : void 0) != null;
    if (!contextMap) {
      return;
    }
    _results = [];
    for (_i = 0, _len = contextMap.length; _i < _len; _i++) {
      key = contextMap[_i];
      if (contextMap.hasOwnProperty(key) && key.indexOf(channel) !== -1) {
        _results.push(req.undef(key));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };
  mediator.dom = {
    find: function(selector, context) {
      if (context == null) {
        context = document;
      }
      return $(context).find(selector);
    },
    data: function(selector, attribute) {
      return $(selector).data(attribute);
    }
  };
  fusebox = {
    noConflict: function() {
      root.fusebox = previousFusebox;
      return fusebox;
    },
    subscribe: function(subscriber, channel, callback) {
      if (permissions.validate(subscriber, channel)) {
        return mediator.subscribe(subscriber, channel, callback, this);
      }
    },
    publish: function(subscriber) {
      return mediator.publish.apply(mediator, arguments);
    },
    start: function(subscriber) {
      return mediator.start.apply(mediator, arguments);
    },
    stop: function(subscriber) {
      return mediator.stop.apply(mediator, arguments);
    },
    unload: function(subscriber) {
      var file;

      file = decamelize(channel);
      return mediator.unload.apply(baseUrl + file);
    },
    find: function(selector, context) {
      return mediator.dom.find(selector, context);
    },
    data: function(selector, attribute) {
      return mediator.dom.data(selector, attribute);
    },
    permissions: permissions,
    dom: mediator.dom,
    setBaseUrl: function(url) {
      return baseUrl = url;
    },
    getBaseUrl: function() {
      return baseUrl;
    },
    setRequireLib: function(reqFunc, reqGlobal) {
      var require, requirejs;

      if (arguments.length < 2) {
        throw new Error('Both a require function and a requirejs global are needed');
      }
      if (typeof reqFunc !== 'function') {
        throw new Error('require needs to be a function');
      }
      require = reqFunc;
      return requirejs = reqGlobal;
    },
    getRequireLib: function() {
      return {
        require: require,
        requirejs: requirejs
      };
    }
  };
  if (typeof exports !== "undefined" && exports !== null) {
    if ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null) {
      exports = module.exports = fusebox;
    }
    exports.fusebox = fusebox;
  } else {
    root.fusebox = fusebox;
  }
  return fusebox;
})();

/*
//@ sourceMappingURL=fusebox.js.map
*/