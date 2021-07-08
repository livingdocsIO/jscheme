# Property Validator
# ------------------

module.exports = class PropertyValidator
  termRegex = /[^, ][^,]*[^, ]/g

  # @params
  #  - inputString { String } Validation String. E.g. 'string, optional'
  #  - scheme { Scheme }
  #  - property { String} Optional. Name of the property this validator is defined upon.
  #  - parent { PropertyValidator } Optional.
  constructor: ({ @inputString, @scheme, @property, @parent }) ->
    @validators = []
    @location = @getLocation()
    @parent?.addRequiredProperty(@property) if @scheme.propertiesRequired
    @addValidations(@inputString)


  getLocation: ->
    if not @property?
      ''
    else if @parent?
      @parent.location + @scheme.writeProperty(@property)
    else
      @scheme.writeProperty(@property)


  getPropLocation: (key) ->
    "#{ @location }#{ @scheme.writeProperty(key) }"


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
    return isValid if not value? && @isOptional()

    validators = @scheme.validators
    for name in @validators || []
      validator = validators[name]
      return errors.add("missing validator #{ name }", location: @location) unless validator?

      validationResult = validator(value)
      continue if validationResult == true
      errors.add(validationResult, location: @location, defaultMessage: "#{ name } validator failed")
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
      validationResult = validator(entry)
      continue if validationResult == true
      location = "#{ @location }[#{ index }]"
      errors.add(validationResult, location: location, defaultMessage: "#{ @arrayValidator } validator failed")
      isValid = false

    isValid


  validateOtherProperty: (key, value, errors) ->
    if @otherPropertyValidator?
      @scheme.errors = undefined
      return true if isValid = @otherPropertyValidator.call(this, key, value)

      if @scheme.errors?
        errors.join(@scheme.errors, location: @getPropLocation(key))
      else
        errors.add("additional property check failed", location: @getPropLocation(key))

      false
    else
      if @scheme.allowAdditionalProperties
        true
      else
        errors.add("unspecified additional property", location: @getPropLocation(key))
        false


  validateRequiredProperties: (obj, errors) ->
    isValid = true
    for key, isRequired of @requiredProperties
      if not obj[key]? && isRequired
        errors.add("required property missing", location: @getPropLocation(key))
        isValid = false

    isValid


  addRequiredProperty: (key) ->
    @requiredProperties ?= {}
    @requiredProperties[key] = true


  removeRequiredProperty: (key) ->
    @requiredProperties?[key] = undefined


  # A property is only considered optional if it has a parent.
  # Root objects can not be optional.
  isOptional: ->
    not @parent.requiredProperties[@property] == true if @parent?


