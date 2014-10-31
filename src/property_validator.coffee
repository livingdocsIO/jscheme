# Property Validator
# ------------------

module.exports = class PropertyValidator
  termRegex = /\w[\w ]*\w/g

  # @params
  #  - inputString { String } Validation String. E.g. 'string, optional'
  #  - scheme { Scheme }
  #  - property { String} Optional. Name of the property this validator is defined upon.
  #  - parent { PropertyValidator } Optional.
  constructor: ({ @inputString, @scheme, @property, @parent }) ->
    @validators = []
    @location = @getLocation()
    @parent?.addRequiredProperty(@property) if @scheme.namedPropertiesRequired
    @addValidations(@inputString)


  getLocation: ->
    if not @property?
      ''
    else if @parent?
      @parent.location + @scheme.writeProperty(@property)
    else
      @scheme.writeProperty(@property)


  addValidations: (configString) ->
    while result = termRegex.exec(configString)
      term = result[0]
      if term == 'optional'
        @parent.removeRequiredProperty(@property)
      else if term == 'required'
        @parent.addRequiredProperty(@property)
      else if term.indexOf('array of ') == 0
        @validators.push('array')
        @arrayValidator = term.slice(9)
      else if term.indexOf(' or ') != -1
        types = term.split(' or ')
        console.log('todo')
      else
        @validators.push(term)

    undefined


  validate: (value, errors) ->
    isValid = true
    validators = @scheme.validators
    for name in @validators || []
      validator = validators[name]
      return errors.add("missing validator #{ name }", location: @location) unless validator?

      continue if valid = validator(value) == true
      errors.add(valid, location: @location, defaultMessage: "#{ name } validator failed")
      isValid = false

    return false if not isValid = @validateArray(value, errors)
    return false if not isValid = @validateRequiredProperties(value, errors)

    isValid


  validateArray: (arr, errors) ->
    return true unless @arrayValidator?
    isValid = true

    validator = @scheme.validators[@arrayValidator]
    return errors.add("missing validator #{ @arrayValidator }", location: @location) unless validator?

    for entry, index in arr || []
      res = validator(entry)
      continue if res == true
      location = "#{ @location }[#{ index }]"
      errors.add(res, location: location, defaultMessage: "#{ @arrayValidator } validator failed")
      isValid = false

    isValid


  validateOtherProperty: (key, value, errors) ->
    if @otherPropertyValidator?
      @scheme.errors = undefined
      return true if isValid = @otherPropertyValidator.call(this, key, value)

      if @scheme.errors?
        errors.join(@scheme.errors, location: "#{ @location }#{ @scheme.writeProperty(key) }")
      else
        errors.add("additional property check failed", location: "#{ @location }#{ @scheme.writeProperty(key) }")

      false
    else
      if @scheme.allowAdditionalProperties
        true
      else
        errors.add("unspecified additional property", location: "#{ @location }#{ @scheme.writeProperty(key) }")
        false


  validateRequiredProperties: (obj, errors) ->
    isValid = true
    for key, isRequired of @requiredProperties
      if not obj[key]? && isRequired
        errors.add("required property missing", location: "#{ @location }#{ @scheme.writeProperty(key) }")
        isValid = false

    isValid


  addRequiredProperty: (key) ->
    @requiredProperties ?= {}
    @requiredProperties[key] = true


  removeRequiredProperty: (key) ->
    @requiredProperties?[key] = undefined

