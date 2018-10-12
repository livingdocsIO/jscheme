jScheme = require('../../src/jscheme')

describe 'jscheme', ->

  beforeEach ->
    @schema = jScheme.new()


  describe 'add()', ->

    it 'adds a schema', ->
      @schema.add 'test', {}

      expect(@schema.schemas['test']).to.exist

    it 'adds a __validator property to the schema', ->
      @schema.add 'test',
        property: 'string'

      expect(@schema.schemas['test']['property']['__validator']).to.exist


    it 'creates a validator for the property', ->
      @schema.add 'test',
        property: 'string'

      validator = @schema.schemas['test']['property']['__validator']
      expect(validator.location).to.equal('.property')


    it 'adds a validator location at the second level', ->
      @schema.add 'test',
        levelOne:
          levelTwo: 'string'

      validator = @schema.schemas['test']['levelOne']['levelTwo']['__validator']
      expect(validator.location).to.equal('.levelOne.levelTwo')


  describe 'validate()', ->

    describe 'a schema with one property', ->

      beforeEach ->
        @schema.add 'test',
          name: 'string'


      it 'validates a valid entry', ->
        isValid = @schema.validate 'test',
          name: 'I am a valid entry'

        expect(isValid).to.equal(true)


      it 'validates a valid entry with an additional field', ->
        isValid = @schema.validate 'test',
          name: 'I am a valid entry'
          anotherProperty: true

        expect(isValid).to.equal(true)


      it 'records an error for an missing property', ->
        isValid = @schema.validate 'test',
          anotherProperty: 'there is something missing here'

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0]).to.equal("test.name: required property missing")


      it 'records an error for an invalid property type', ->
        isValid = @schema.validate 'test',
          name: false

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0]).to.equal('test.name: string validator failed')


    describe 'a schema with additional properties', ->

      beforeEach ->
        @schema.add 'additionalProperty',
          property: 'string'
          __additionalProperty: -> false


      it 'records an error with an additional field', ->
        isValid = @schema.validate 'additionalProperty',
          property: 'I am a valid entry'
          anotherProperty: true

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0])
        .to.equal('additionalProperty.anotherProperty: additional property check failed')


    describe 'unknown root schema', ->

      it 'records an error with an unknown schema', ->
        isValid = @schema.validate 'unknownSchema', {}
        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0])
        .to.equal('unknownSchema: missing schema')


    describe 'configure(allowAdditionalProperties: false)', ->

      beforeEach ->
        @schema.configure
          allowAdditionalProperties: false

        @schema.add 'rigidObj',
          property: 'string'


      it 'records an error with an additional field', ->
        isValid = @schema.validate 'rigidObj',
          property: 'sure thing'
          anotherProperty: true

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0])
        .to.equal('rigidObj.anotherProperty: unspecified additional property')


    describe 'configure(propertiesRequired: false)', ->

      beforeEach ->
        @schema.configure
          propertiesRequired: false

        @schema.add 'optionalObj',
          property: 'string'

        @schema.add 'declared',
          required: 'string, required'
          optional: 'string'


      it 'validates an empty optional object', ->
        isValid = @schema.validate 'optionalObj', {}
        expect(isValid).to.equal(true)


      it 'validates an declared requirement', ->
        isValid = @schema.validate 'declared',
          required: 'yep'

        expect(isValid).to.equal(true)


      it 'validates an optional value that is set to "null"', ->
        isValid = @schema.validate 'declared',
          required: 'yep'
          optional: null

        expect(isValid).to.equal(true)


      it 'records a missing declared required property', ->
        isValid = @schema.validate 'declared',
          optional: 'nope'

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0])
          .to.equal('declared.required: required property missing')


    describe 'a schema with an optional property', ->

      beforeEach ->
        @schema.add 'optionalProperty',
          id: 'string'
          name: 'string, optional'


      it 'validates a missing optional field', ->
        isValid = @schema.validate 'optionalProperty',
          id: 'AAA'

        expect(isValid).to.equal(true)


      it 'validates an optional field that is set to "undefined"', ->
        isValid = @schema.validate 'optionalProperty',
          id: 'AAA'
          name: undefined

        expect(isValid).to.equal(true)



    describe 'a schema with two levels', ->

      beforeEach ->
        @schema.add 'test',
          levelOne:
            levelTwo: 'string'


      it 'validates a valid entry', ->
        isValid = @schema.validate 'test',
          levelOne:
            levelTwo: 'I am a valid second level entry'

        expect(isValid).to.equal(true)


      it 'records an error for an invalid first level entry', ->
        isValid = @schema.validate 'test',
          levelOne: 'invalid'

        expect(isValid).to.equal(false)


      it 'records an error for an invalid second level entry', ->
        isValid = @schema.validate 'test',
          levelOne:
            levelTwo:
              levelThree: 'one too many'

        expect(isValid).to.equal(false)


      it 'records an error for an empty object', ->
        isValid = @schema.validate 'test',
          levelOne: {}

        expect(isValid).to.equal(false)


    describe 'a validator with dashes in its name', ->

      beforeEach ->
        @schema.add 'validator-with-a-dash', (value) ->
          value == 'valid'

        @schema.add 'template',
          test: 'validator-with-a-dash'


      it 'the validator is recognized', ->
        isValid = @schema.validate 'template',
          test: 'valid'

        expect(isValid).to.equal(true)


    describe 'a schema with a nested type', ->

      beforeEach ->
        @schema.add 'nested type',
          template: 'template'

        @schema.add 'template',
          id: 'number'
          name: 'string'


      it 'validates a nested type', ->
        isValid = @schema.validate 'nested type',
          template:
            id: 1
            name: 'just another template'

        expect(isValid).to.equal(true)


      it 'records an error for an invalid nested type', ->
        isValid = @schema.validate 'nested type',
          template:
            id: false
            name: 'just another template'

        expect(isValid).to.equal(false)


      it 'records an error for a nested type with the wrong property', ->
        isValid = @schema.validate 'nested type',
          template:
            id: 1
            nameMisspelled: 'just another template'

        expect(isValid).to.equal(false)


    describe 'a schema with a missing template', ->

      beforeEach ->
        @schema.add 'record',
          id: 'uuid'


      it 'records an error for a missing template', ->
        isValid = @schema.validate 'record',
          id: '1'

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0]).to.equal('record.id: missing validator uuid')


    describe 'a schema with an array of strings', ->

      beforeEach ->
        @schema.add 'obj',
          words: 'array of string'


      it 'validates an array of strings', ->
        isValid = @schema.validate 'obj',
          words: ['hey', 'you']

        expect(isValid).to.equal(true)


      it 'records an error for an array of numbers', ->
        isValid = @schema.validate 'obj',
          words: [1, 2]

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0]).to.equal('obj.words[0]: string validator failed')


    describe 'a schema with an array of a nested type', ->

      beforeEach ->
        @schema.add 'templates',
          templates: 'array of template'

        @schema.add 'template',
          id: 'number'
          name: 'string'


      it 'validates an array with two entries', ->
        isValid = @schema.validate 'templates',
          templates: [
            id: 1
            name: 'just another template'
          ,
            id: 2
            name: 'just another template'
          ]

        expect(isValid).to.equal(true)


      it 'validates an empty array', ->
        isValid = @schema.validate 'templates',
          templates: []

        expect(isValid).to.equal(true)


      it 'records an error for a missing array', ->
        isValid = @schema.validate 'templates',
          templates: undefined

        expect(isValid).to.equal(false)


      it 'records an error for an invalid array entry', ->
        isValid = @schema.validate 'templates',
          templates: [
            id: 1
          ]

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0])
        .to.equal('templates.templates[0].name: required property missing')


    describe 'a schema with password confirmation', ->

      beforeEach ->
        @schema.add 'confirmPassword', (obj) ->
          obj.password == obj.passwordConfirmation

        @schema.add 'password',
          __validate: 'confirmPassword'
          password: 'string, not empty'
          passwordConfirmation: 'string'


      it 'validates a valid object', ->
        isValid = @schema.validate 'password',
          password: '1234'
          passwordConfirmation: '1234'

        expect(isValid).to.equal(true)


      it 'records an error for a mistyped password confirmation', ->
        isValid = @schema.validate 'password',
          password: '1234'
          passwordConfirmation: '1235'

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0])
        .to.equal('password: confirmPassword validator failed')


    describe 'custom error message for a validator', ->

      beforeEach ->
        @schema.add 'errorMessage', (obj) ->
          'custom error message'

        @schema.add 'obj',
          param: 'errorMessage'


      it 'returns the custom error message', ->
        isValid = @schema.validate('obj', param: 'something')
        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0]).to.equal('obj.param: custom error message')


    describe 'validator which returns undefined', ->

      beforeEach ->
        @schema.add 'incorrectValidator', (obj) ->
          undefined

        @schema.add 'obj',
          param: 'incorrectValidator'


      it 'returns a specific error message', ->
        isValid = @schema.validate('obj', param: 'something')
        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0]).to.equal('obj.param: validator returned undefined. Check your validator implementation.')


    describe 'a schema with a custom validator in a nested object', ->

      beforeEach ->
        @schema.add 'phone', (value) ->
          /\d{7,12}/.test(value)

        @schema.add 'account',
          person:
            name: 'string'
            phone: 'string, phone'


      it 'validates a valid object', ->
        isValid = @schema.validate 'account',
          person:
            name: 'Peter Pan'
            phone: '0764352253'

        expect(isValid).to.equal(true)


      it 'records an error for an invalid phone number', ->
        isValid = @schema.validate 'account',
          person:
            name: 'Peter Pan'
            phone: 'no number here'

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages()[0])
        .to.equal('account.person.phone: phone validator failed')


    describe 'a schema wich calls validate', ->

      beforeEach ->
        @schema.add 'obj',
          persons:
            __additionalProperty: (key, value) => @schema.validate('person', value)

        @schema.add 'person',
          name: 'string'
          place: 'string'


      it 'validates a valid object', ->
        isValid = @schema.validate 'obj',
          persons:
            '1':
              name: 'Peter Pan'
              place: 'Neverland'

        expect(isValid).to.equal(true)


      it 'records an error for an invalid child object', ->
        isValid = @schema.validate 'obj',
          persons:
            '1':
              name: 'Lucky Luke'

        expect(isValid).to.equal(false)
        expect(@schema.getErrorMessages().length).to.equal(1)
        expect(@schema.getErrorMessages()[0])
        .to.equal("obj.persons['1'].place: required property missing")

