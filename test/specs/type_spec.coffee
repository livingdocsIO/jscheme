type = require('../../src/type')

describe 'type', ->

  describe 'isObject()', ->

    it 'recognizes an object', ->
      expect( type.isObject({}) ).to.equal(true)


    it 'returns false for a method', ->
      expect( type.isObject(->) ).to.equal(false)


    it 'returns false for an array', ->
      expect( type.isObject([]) ).to.equal(false)


    it 'returns false for a string', ->
      expect( type.isObject('a') ).to.equal(false)


    it 'returns false "false"', ->
      expect( type.isObject(false) ).to.equal(false)


    it 'returns false "true"', ->
      expect( type.isObject(true) ).to.equal(false)


  describe 'isBoolean()', ->

    it 'recognizes true', ->
      expect( type.isBoolean(true) ).to.equal(true)


    it 'returns false for an empty string', ->
      expect( type.isBoolean('') ).to.equal(false)


  describe 'isFunction()', ->

    it 'recognizes an empty method', ->
      expect( type.isFunction(->) ).to.equal(true)


  describe 'isString()', ->

    it 'recognizes a string', ->
      expect( type.isString('a') ).to.equal(true)


    it 'recognizes new String()', ->
      expect( type.isString(new String('')) ).to.equal(true)


  describe 'isArray()', ->

    it 'recognizes an array', ->
      expect( type.isArray([]) ).to.equal(true)


    it 'returns false for an object', ->
      expect( type.isArray({}) ).to.equal(false)

