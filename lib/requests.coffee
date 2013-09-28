request = require 'request'
parseString = require('xml2js').parseString

module.exports.curlRequest = (url, done) ->
	unless url then return done new Error 'no url provided'
	request url, (error, response, body) ->
  		if error then return done error
  		if response?.statusCode is 200
  			parseString body, done
  		else
  			console.log response.statusCode + '  returned: ', body
  			done response

