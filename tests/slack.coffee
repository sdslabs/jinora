slack = require "../slack"
assert = require "assert"

expected = {"1": "one", "2": "two"}
list = {"list": [
  {
    id: "1",
    name: "one"
  },{
    id: "2",
    name: "two"
  }
]}

assert.deepEqual expected, slack.listToHash list , "list"