(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Scheme, jScheme;

Scheme = require('./scheme');

jScheme = new Scheme();

jScheme["new"] = function() {
  return new Scheme();
};

module.exports = jScheme;

if (typeof window !== "undefined" && window !== null) {
  window.jScheme = jScheme;
}



},{"./scheme":3}],2:[function(require,module,exports){
var PropertyValidator;

module.exports = PropertyValidator = (function() {
  var termRegex;

  termRegex = /\w[\w ]*\w/g;

  function PropertyValidator(_arg) {
    var _ref;
    this.inputString = _arg.inputString, this.scheme = _arg.scheme, this.property = _arg.property, this.parent = _arg.parent;
    this.validators = [];
    this.location = this.getLocation();
    if (this.scheme.propertiesRequired) {
      if ((_ref = this.parent) != null) {
        _ref.addRequiredProperty(this.property);
      }
    }
    this.addValidations(this.inputString);
  }

  PropertyValidator.prototype.getLocation = function() {
    if (this.property == null) {
      return '';
    } else if (this.parent != null) {
      return this.parent.location + this.scheme.writeProperty(this.property);
    } else {
      return this.scheme.writeProperty(this.property);
    }
  };

  PropertyValidator.prototype.getPropLocation = function(key) {
    return "" + this.location + (this.scheme.writeProperty(key));
  };

  PropertyValidator.prototype.addValidations = function(configString) {
    var result, term, types;
    while (result = termRegex.exec(configString)) {
      term = result[0];
      if (term === 'optional') {
        this.parent.removeRequiredProperty(this.property);
      } else if (term === 'required') {
        this.parent.addRequiredProperty(this.property);
      } else if (term.indexOf('array of ') === 0) {
        this.validators.push('array');
        this.arrayValidator = term.slice(9);
      } else if (term.indexOf(' or ') !== -1) {
        types = term.split(' or ');
        console.log('todo');
      } else {
        this.validators.push(term);
      }
    }
    return void 0;
  };

  PropertyValidator.prototype.validate = function(value, errors) {
    var isValid, name, validationResult, validator, validators, _i, _len, _ref;
    isValid = true;
    if ((value == null) && this.isOptional()) {
      return isValid;
    }
    validators = this.scheme.validators;
    _ref = this.validators || [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      name = _ref[_i];
      validator = validators[name];
      if (validator == null) {
        return errors.add("missing validator " + name, {
          location: this.location
        });
      }
      validationResult = validator(value);
      if (validationResult === true) {
        continue;
      }
      errors.add(validationResult, {
        location: this.location,
        defaultMessage: "" + name + " validator failed"
      });
      isValid = false;
    }
    if (!(isValid = this.validateArray(value, errors))) {
      return false;
    }
    if (!(isValid = this.validateRequiredProperties(value, errors))) {
      return false;
    }
    return isValid;
  };

  PropertyValidator.prototype.validateArray = function(arr, errors) {
    var entry, index, isValid, location, validationResult, validator, _i, _len, _ref;
    if (this.arrayValidator == null) {
      return true;
    }
    isValid = true;
    validator = this.scheme.validators[this.arrayValidator];
    if (validator == null) {
      return errors.add("missing validator " + this.arrayValidator, {
        location: this.location
      });
    }
    _ref = arr || [];
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      entry = _ref[index];
      validationResult = validator(entry);
      if (validationResult === true) {
        continue;
      }
      location = "" + this.location + "[" + index + "]";
      errors.add(validationResult, {
        location: location,
        defaultMessage: "" + this.arrayValidator + " validator failed"
      });
      isValid = false;
    }
    return isValid;
  };

  PropertyValidator.prototype.validateOtherProperty = function(key, value, errors) {
    var isValid;
    if (this.otherPropertyValidator != null) {
      this.scheme.errors = void 0;
      if (isValid = this.otherPropertyValidator.call(this, key, value)) {
        return true;
      }
      if (this.scheme.errors != null) {
        errors.join(this.scheme.errors, {
          location: this.getPropLocation(key)
        });
      } else {
        errors.add("additional property check failed", {
          location: this.getPropLocation(key)
        });
      }
      return false;
    } else {
      if (this.scheme.allowAdditionalProperties) {
        return true;
      } else {
        errors.add("unspecified additional property", {
          location: this.getPropLocation(key)
        });
        return false;
      }
    }
  };

  PropertyValidator.prototype.validateRequiredProperties = function(obj, errors) {
    var isRequired, isValid, key, _ref;
    isValid = true;
    _ref = this.requiredProperties;
    for (key in _ref) {
      isRequired = _ref[key];
      if ((obj[key] == null) && isRequired) {
        errors.add("required property missing", {
          location: this.getPropLocation(key)
        });
        isValid = false;
      }
    }
    return isValid;
  };

  PropertyValidator.prototype.addRequiredProperty = function(key) {
    if (this.requiredProperties == null) {
      this.requiredProperties = {};
    }
    return this.requiredProperties[key] = true;
  };

  PropertyValidator.prototype.removeRequiredProperty = function(key) {
    var _ref;
    return (_ref = this.requiredProperties) != null ? _ref[key] = void 0 : void 0;
  };

  PropertyValidator.prototype.isOptional = function() {
    if (this.parent != null) {
      return !this.parent.requiredProperties[this.property] === true;
    }
  };

  return PropertyValidator;

})();



},{}],3:[function(require,module,exports){
var PropertyValidator, Scheme, ValidationErrors, type, validators;

ValidationErrors = require('./validation_errors');

PropertyValidator = require('./property_validator');

validators = require('./validators');

type = require('./type');

module.exports = Scheme = (function() {
  var jsVariableName;

  jsVariableName = /^[a-zA-Z]\w*$/;

  function Scheme() {
    this.validators = Object.create(validators);
    this.schemas = {};
    this.propertiesRequired = true;
    this.allowAdditionalProperties = true;
  }

  Scheme.prototype.configure = function(_arg) {
    this.propertiesRequired = _arg.propertiesRequired, this.allowAdditionalProperties = _arg.allowAdditionalProperties;
  };

  Scheme.prototype.add = function(name, schema) {
    if (type.isFunction(schema)) {
      this.addValidator(name, schema);
    } else {
      this.addSchema(name, this.parseConfigObj(schema, void 0, name));
    }
    return this;
  };

  Scheme.prototype.addSchema = function(name, schema) {
    if (this.validators[name] != null) {
      throw new Error("A validator is alredy registered under this name: " + name);
    }
    this.schemas[name] = schema;
    this.validators[name] = (function(_this) {
      return function(value) {
        var errors;
        errors = _this.recursiveValidate(schema, value);
        if (errors.hasErrors()) {
          return errors;
        } else {
          return true;
        }
      };
    })(this);
    return this;
  };

  Scheme.prototype.addValidator = function(name, func) {
    this.validators[name] = func;
    return this;
  };

  Scheme.prototype.validate = function(schemaName, obj) {
    var schema;
    this.errors = void 0;
    schema = this.schemas[schemaName];
    if (schema == null) {
      this.errors = new ValidationErrors();
      this.errors.add("missing schema", {
        location: schemaName
      });
      return false;
    }
    this.errors = this.recursiveValidate(schema, obj).setRoot(schemaName);
    return !this.errors.hasErrors();
  };

  Scheme.prototype.hasErrors = function() {
    var _ref;
    return (_ref = this.errors) != null ? _ref.hasErrors() : void 0;
  };

  Scheme.prototype.getErrorMessages = function() {
    var _ref;
    return (_ref = this.errors) != null ? _ref.getMessages() : void 0;
  };

  Scheme.prototype.recursiveValidate = function(schemaObj, obj) {
    var errors, isValid, key, parentValidator, propertyValidator, value;
    parentValidator = schemaObj['__validator'];
    errors = new ValidationErrors();
    parentValidator.validate(obj, errors);
    for (key in obj) {
      value = obj[key];
      if (schemaObj[key] != null) {
        propertyValidator = schemaObj[key]['__validator'];
        isValid = propertyValidator.validate(value, errors);
        if (isValid && (propertyValidator.childSchemaName == null) && type.isObject(value)) {
          errors.join(this.recursiveValidate(schemaObj[key], value));
        }
      } else {
        parentValidator.validateOtherProperty(key, value, errors);
      }
    }
    return errors;
  };

  Scheme.prototype.parseConfigObj = function(obj, parentValidator) {
    var key, propValidator, value;
    if (parentValidator == null) {
      parentValidator = new PropertyValidator({
        inputString: 'object',
        scheme: this
      });
    }
    for (key in obj) {
      value = obj[key];
      if (this.addParentValidator(parentValidator, key, value)) {
        continue;
      }
      if (type.isString(value)) {
        propValidator = new PropertyValidator({
          inputString: value,
          property: key,
          parent: parentValidator,
          scheme: this
        });
        obj[key] = {
          '__validator': propValidator
        };
      } else if (type.isObject(value)) {
        propValidator = new PropertyValidator({
          inputString: 'object',
          property: key,
          parent: parentValidator,
          scheme: this
        });
        obj[key] = this.parseConfigObj(value, propValidator);
      }
    }
    obj['__validator'] = parentValidator;
    return obj;
  };

  Scheme.prototype.addParentValidator = function(parentValidator, key, validator) {
    switch (key) {
      case '__validate':
        parentValidator.addValidations(validator);
        break;
      case '__additionalProperty':
        if (type.isFunction(validator)) {
          parentValidator.otherPropertyValidator = validator;
        }
        break;
      default:
        return false;
    }
    return true;
  };

  Scheme.prototype.writeProperty = function(value) {
    if (jsVariableName.test(value)) {
      return "." + value;
    } else {
      return "['" + value + "']";
    }
  };

  return Scheme;

})();



},{"./property_validator":2,"./type":4,"./validation_errors":5,"./validators":6}],4:[function(require,module,exports){
var toString, type;

toString = Object.prototype.toString;

module.exports = type = {
  isObject: function(obj) {
    var t;
    t = typeof obj;
    return t === 'object' && !!obj && !this.isArray(obj);
  },
  isBoolean: function(obj) {
    return obj === true || obj === false || toString.call(obj) === '[object Boolean]';
  }
};

['Function', 'String', 'Number', 'Date', 'RegExp', 'Array'].forEach(function(name) {
  return type["is" + name] = function(obj) {
    return toString.call(obj) === ("[object " + name + "]");
  };
});

if (Array.isArray) {
  type.isArray = Array.isArray;
}



},{}],5:[function(require,module,exports){
var ValidationErrors, type;

type = require('./type');

module.exports = ValidationErrors = (function() {
  function ValidationErrors() {}

  ValidationErrors.prototype.hasErrors = function() {
    return this.errors != null;
  };

  ValidationErrors.prototype.setRoot = function(root) {
    this.root = root;
    return this;
  };

  ValidationErrors.prototype.add = function(message, _arg) {
    var defaultMessage, error, location, _ref;
    _ref = _arg != null ? _arg : {}, location = _ref.location, defaultMessage = _ref.defaultMessage;
    if (message === false) {
      message = defaultMessage;
    }
    if (message === void 0) {
      message = "validator returned undefined. Check your validator implementation.";
    }
    if (this.errors == null) {
      this.errors = [];
    }
    if (type.isString(message)) {
      this.errors.push({
        path: location,
        message: message
      });
    } else if (message instanceof ValidationErrors) {
      this.join(message, {
        location: location
      });
    } else if (message.path && message.message) {
      error = message;
      this.errors.push({
        path: location + error.path,
        message: error.message
      });
    } else {
      throw new Error('ValidationError.add() unknown error type');
    }
    return false;
  };

  ValidationErrors.prototype.join = function(_arg, _arg1) {
    var error, errors, location, _i, _len, _results;
    errors = _arg.errors;
    location = (_arg1 != null ? _arg1 : {}).location;
    if (errors == null) {
      return;
    }
    if (errors.length) {
      if (this.errors == null) {
        this.errors = [];
      }
      _results = [];
      for (_i = 0, _len = errors.length; _i < _len; _i++) {
        error = errors[_i];
        _results.push(this.errors.push({
          path: (location || '') + error.path,
          message: error.message
        }));
      }
      return _results;
    }
  };

  ValidationErrors.prototype.getMessages = function() {
    var error, messages, _i, _len, _ref;
    messages = [];
    _ref = this.errors || [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      error = _ref[_i];
      messages.push("" + (this.root || '') + error.path + ": " + error.message);
    }
    return messages;
  };

  return ValidationErrors;

})();



},{"./type":4}],6:[function(require,module,exports){
var type;

type = require('./type');

module.exports = {
  'object': function(value) {
    return type.isObject(value);
  },
  'string': function(value) {
    return type.isString(value);
  },
  'boolean': function(value) {
    return type.isBoolean(value);
  },
  'number': function(value) {
    return type.isNumber(value);
  },
  'function': function(value) {
    return type.isFunction(value);
  },
  'date': function(value) {
    return type.isDate(value);
  },
  'regexp': function(value) {
    return type.isRegExp(value);
  },
  'array': function(value) {
    return type.isArray(value);
  },
  'falsy': function(value) {
    return !!value === false;
  },
  'truthy': function(value) {
    return !!value === true;
  },
  'not empty': function(value) {
    return !!value === true;
  },
  'deprecated': function(value) {
    return true;
  }
};



},{"./type":4}]},{},[1]);
