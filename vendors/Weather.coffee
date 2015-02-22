req = require '../lib/requests'
_ = require 'underscore'

module.exports = class Weather

	# http://forecast.weather.gov/MapClick.php?lat=37.77493&lon=-122.41942&FcstType=digitalDWML
	baseUrl = 'http://forecast.weather.gov/MapClick.php?FcstType=digitalDWML&'
	alamedaLocation = "lat=37.7735&lon=-122.279"

	getCurrentTemp: (done) ->
		url = baseUrl + alamedaLocation
		req.curlRequest url, (error, info) =>
			if error or typeof(info?.dwml?.data?[0]['parameters']?[0].temperature?[0]) isnt 'object'
				return done new Error 'Temp error'
			temperatureData = _.find(info.dwml.data[0]['parameters'][0].temperature, (d) ->
				if d.$.type == 'hourly' then true
			)
			currentTemp = temperatureData?.value[0] ? '--'
			done null, currentTemp + '°'

	getChanceOfRain: (image, done) ->
		url = baseUrl + alamedaLocation
		req.curlRequest url, (error, info) =>
			if error or
			typeof(info?.dwml?.data?[0]['parameters']?[0]['probability-of-precipitation']?[0]) isnt 'object'
				return done new Error 'Rain error'
			chance = info.dwml.data[0]['parameters'][0]['probability-of-precipitation'][0].value[0]
			#TODO - determine which image to show for which percentage - will also need 'cloud-amount'
			iconName = switch
				when chance > 60 then 'rain'
				when chance > 20 then 'overcast'
				else 'sunny'
			done null, iconName

	getTempAndRain: (done) ->
		url = baseUrl + alamedaLocation
		req.curlRequest url, (error, info) =>
			if error or typeof(info?.dwml?.data?[0]['parameters']?[0].temperature?[0]) isnt 'object'
				return done new Error 'Temp error'
			currentTemp = info.dwml.data[0]['parameters'][0].temperature[0].value[0]
			chance = info.dwml.data[0]['parameters'][0]['probability-of-precipitation'][0].value[0]
			currentTemp = currentTemp + '° '
			chance = if chance > 5 then chance + '%' else ''
			done null, currentTemp + chance
