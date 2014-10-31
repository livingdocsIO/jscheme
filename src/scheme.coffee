ValidationErrors = require('./validation_errors')
PropertyValidator = require('./property_validator')
validators = require('./validators')
type = require('./type')

module.exports = class Scheme
  jsVariableName = /^[a-zA-Z]\w*$/

  constructor: ->
    @validators = Object.create(validators)
    @schemas = {}
    @namedPropertiesRequired = true
    @allowAdditionalProperties = true


  configure: ({ @namedPropertiesRequired, @allowAdditionalProperties }) ->


  add: (name, schema) ->
    if type.isFunction(schema)
      @addValidator(name, schema)
    else
      @addSchema(name, @parseConfigObj(schema, undefined, name))

    this


  addSchema: (name, schema) ->
    if @validators[name]?
      throw new Error("A validator is alredy registered under this name: #{ name }")

    @schemas[name] = schema
    @validators[name] = (value) =>
      errors = @recursiveValidate(schema, value)
      return if errors.hasErrors() then errors else true

    this


  addValidator: (name, func) ->
    @validators[name] = func
    this


  # @returns { Boolean } returns if the object is valid or not.
  validate: (schemaName, obj) ->
    @errors = undefined
    schema = @schemas[schemaName]
    unless schema?
      @errors = new ValidationErrors()
      @errors.add("missing schema", location: schemaName)
      return false
    @errors = @recursiveValidate(schema, obj).setRoot(schemaName)
    return not @errors.hasErrors()


  hasErrors: ->
    @errors?.hasErrors()


  getErrorMessages: ->
    @errors?.getMessages()


  # Recursive validate
  # Used to travel the input object recursively.
  # For internal use only.
  #
  # @returns { ValidationErrors obj } An object which contains validation errors.
  recursiveValidate: (schemaObj, obj) ->
    parentValidator = schemaObj['__validator']
    errors = new ValidationErrors()
    parentValidator.validate(obj, errors)

    for key, value of obj
      if schemaObj[key]?
        propertyValidator = schemaObj[key]['__validator']
        isValid = propertyValidator.validate(value, errors)
        if isValid && not propertyValidator.childSchemaName? && type.isObject(value)
          errors.join(@recursiveValidate(schemaObj[key], value))
      else
        parentValidator.validateOtherProperty(key, value, errors)

    errors


  parseConfigObj: (obj, parentValidator) ->
    parentValidator ?= new PropertyValidator(inputString: 'object', scheme: this)

    for key, value of obj
      continue if @addParentValidator(parentValidator, key, value)

      if type.isString(value)
        propValidator = new PropertyValidator(inputString: value, property: key, parent: parentValidator, scheme: this)
        obj[key] = { '__validator': propValidator }
      else if type.isObject(value)
        propValidator = new PropertyValidator(inputString: 'object', property: key, parent: parentValidator, scheme: this)
        obj[key] = @parseConfigObj(value, propValidator)

    obj['__validator'] = parentValidator
    obj


  addParentValidator: (parentValidator, key, validator) ->
    switch key
      when '__validate'
        parentValidator.addValidations(validator)
      when '__additionalProperty'
        if type.isFunction(validator)
          parentValidator.otherPropertyValidator = validator
      else
        return false

    return true


  writeProperty: (value) ->
    if jsVariableName.test(value) then ".#{ value }" else "['#{ value }']"

