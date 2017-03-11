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
			try
				parsed = JSON.parse(body)
				done null, parsed
			catch e
				if e instanceof SyntaxError then logger.debug "not JSON, trying XML", e
				else return done e
				parseString body, done
		else
			logger.warn response.statusCode + '  returned: ', body
			done response
