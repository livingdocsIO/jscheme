# jScheme

A small and simple object schema library for the browser and node. 
It has no dependencies and comes in under 3KB compressed and gzipped.

### Basic Usage

Here is a most simple example to validate an object with one property which has to be a string:

```javascript
// Add a schema.
jScheme.add('person', {
    name: 'string'
}); 

// Validate a valid object against our first schema.
jScheme.validate('person', {
    name: 'Popeye'
});

// Let's see what happens if we check with an empty object.
jScheme.validate('person', {}); // false
jScheme.hasErrors(); // true
jScheme.getErrorMessages(); // ['person.name: required property missing']
```

### Validators

You can add one or more validators to a property in a comma-separated validation string:

Like this: `property: 'boolean, optional'`


#### Predefined Validators

For your convenience there are a few predefined validators:

 - `string`
 - `boolean`
 - `number`
 - `function`
 - `array`
 - `date`
 - `regexp`
 - `object`
 - `falsy`
 - `truthy`
 - `not empty`  
   In fact the same as 'truthy' but it reads nicer, doesn't it?


#### Special Validators

 - `array of {{ validator }}`  
   E.g. 'array of string'
 - `optional`  
   By default all propoerties you specify are required. With this no more.


#### Special Properties

 - `__validate`  
   Adds a validation to the parent property.
 - `__additionalProperty`  
   Here you can define a method that will be called for every unspecified additional property. The methods signature looks like this: `function(key, value) { return false }`.


### A more complex example

```javascript
// Let's try a more feisty schema
jScheme.add('person', {
    name: 'string'
    specialPowers:
        __additionalProperty: function(key, value) { return jScheme.validate('power', value) }
    relationshipStatus: 'relationship status'
    archenemies: 'array of villain, optional'
}); 

// Add another schema that can be nested in the first one
jScheme.add('villain', {
    name: 'string'
    dislikes: 'array of string'
});

jScheme.add('power', {
    hurts: 'boolean'
    hurtsMuch: 'boolean, optional'
});

// Add a custom validator for the relationship status
jScheme.add('relationship status', function(value) {
    return /it\'s (complicated|relaxed|depressing)/.test(value)
});

jScheme.validate('person', {
   name: 'Peter Pan'
   specialPowers:
     'nagging':  { hurts: true }
    relationshipStatus: "it's complicated"
    archenemies: [
        { name: 'John', dislikes: ['baby seals'] },
        { name: 'Mary', dislikes: ['fun', 'flirting'] }
    ]
});
```


### Add your own Validators

You can add your own validators. They are treated just the same as the predefined ones. Also there is no difference if you add a schema or a validator in the way you define them in a validation string. The name of your validator can contain whitespaces so it is easier to read.

```javascript
jScheme.add('your validator', function(value) {
    return true || false
});
```

## License

jScheme is licensed under the [MIT License](LICENSE).

In Short:

- You can use, copy and modify the software however you want.
- You can give the software away for free or sell it.
- The only restriction is that it be accompanied by the license agreement.
