rate_limit_db = {}

module.exports = (socket_id)->
  current_timestamp = new Date
  if rate_limit_db[socket_id]
    diff = current_timestamp - rate_limit_db[socket_id]
    seconds_since_last_message = diff/1000
    return true if seconds_since_last_message <=1
  rate_limit_db[socket_id] = new Date
  return false
