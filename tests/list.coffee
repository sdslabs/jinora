dotenv = require 'dotenv'
dotenv._getKeysAndValuesFromEnvFilePath('../.env');
dotenv._setEnvs();

list = require "../list.coffee"
assert = require "assert"

users = list process.env.API_TOKEN, (fetch)->
  # Online users > 0
  assert fetch().length > 0
  # Online users should include anuma
  assert fetch().indexOf('anuma') > -1