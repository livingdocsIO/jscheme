version = require('../version')
Scheme = require('./scheme')
jScheme = new Scheme()
jScheme.new = ->
  new Scheme()

# Expose version and revision
jScheme.version = version.version
jScheme.revision = version.revision


# Exports
# -------

# Browserify
module.exports = jScheme

# Browser
window.jScheme = jScheme if window?
