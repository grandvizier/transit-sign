req = require '../lib/requests'

module.exports = class Weather

	# http://forecast.weather.gov/MapClick.php?lat=37.77493&lon=-122.41942&FcstType=digitalDWML
	baseUrl = 'http://forecast.weather.gov/MapClick.php?FcstType=digitalDWML&'
	alamedaLocation = "lat=37.77288579232436&lon=-122.25929260253906"

	getCurrentTemp: (done) ->
		url = baseUrl + alamedaLocation
		req.curlRequest url, (error, info) =>
			if error or typeof(info?.dwml?.data?[0]['parameters']?[0].temperature?[0]) isnt 'object'
				return done new Error 'Temp error'
			currentTemp = info.dwml.data[0]['parameters'][0].temperature[0].value[0]
			done null, currentTemp + '°'

	getChanceOfRain: (image, done) ->
		url = baseUrl + alamedaLocation
		req.curlRequest url, (error, info) =>
			if error or 
			typeof(info?.dwml?.data?[0]['parameters']?[0]['probability-of-precipitation']?[0]) isnt 'object'
				return done new Error 'Rain error'
			chance = info.dwml.data[0]['parameters'][0]['probability-of-precipitation'][0].value[0]
			#TODO - determine which image to show for which percentage - will also need 'cloud-amount'
			#if image then getLEDimage()
			done null, chance + '%'