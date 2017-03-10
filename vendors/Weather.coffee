req = require '../lib/requests'
_ = require 'underscore'

module.exports = class Weather

	# https://www.apixu.com/api-explorer.aspx
	baseUrl = 'https://api.apixu.com/v1/current.json?key='
	key = ''
	cityLocation = "q=52.51832,13.45167"
	url = baseUrl + key + '&' + cityLocation

	getCurrentTemp: (done) ->
		req.curlRequest url, (error, weatherinfo) =>
			if error
				return done new Error error
			if not weatherinfo.current
				return done new Error 'Parsing Temp error'
			done null, weatherinfo.current.temp_c + '°'

	getChanceOfRain: (image, done) ->
		console.log("chance of rain")
		req.curlRequest url, (error, info) =>
			if error
				return done new Error 'Rain error'
			console.log info.current.cloud
			console.log info

			chance = info.dwml.data[0]['parameters'][0]['probability-of-precipitation'][0].value[0]
			#TODO - determine which image to show for which percentage - will also need 'cloud-amount'
			iconName = switch
				when chance > 60 then 'rain'
				when chance > 20 then 'overcast'
				else 'sunny'
			done null, iconName

	getTempAndRain: (done) ->
		req.curlRequest url, (error, info) =>
			if error or typeof(info?.dwml?.data?[0]['parameters']?[0].temperature?[0]) isnt 'object'
				return done new Error 'Temp error'
			currentTemp = info.dwml.data[0]['parameters'][0].temperature[0].value[0]
			chance = info.dwml.data[0]['parameters'][0]['probability-of-precipitation'][0].value[0]
			currentTemp = currentTemp + '° '
			chance = if chance > 5 then chance + '%' else ''
			done null, currentTemp + chance
