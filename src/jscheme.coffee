Scheme = require('./scheme')
jScheme = new Scheme()
jScheme.new = ->
  new Scheme()


# Exports
# -------

# Browserify
module.exports = jScheme

# Browser
window.jScheme = jScheme if window?
