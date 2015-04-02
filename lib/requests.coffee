request = require 'request'
logger = require 'winston'
parseString = require('xml2js').parseString

module.exports.curlRequest = (url, done) ->
	unless url then return done new Error 'no url provided'
	request {url: url, headers: {'User-Agent': 'request'}}, (error, response, body) ->
		if error
			logger.info "Curl failed:", url
			return done error
		if response?.statusCode is 200
			parseString body, done
		else
			console.log response.statusCode + '  returned: ', body
			done response
