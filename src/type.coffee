toString = Object.prototype.toString

module.exports = type =

  isObject: (obj) ->
    t = typeof obj
    t == 'object' && !!obj && !@isArray(obj)


  isBoolean: (obj) ->
    obj == true || obj == false || toString.call(obj) == '[object Boolean]'


['Function', 'String', 'Number', 'Date', 'RegExp', 'Array'].forEach (name) ->
  type["is#{ name }"] = (obj) ->
    toString.call(obj) == "[object #{ name }]"


# Use native isArray method if present
type.isArray = Array.isArray if Array.isArray
