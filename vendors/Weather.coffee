req = require '../lib/requests'
_ = require 'underscore'

module.exports = class Weather

	# https://www.apixu.com/api-explorer.aspx
	baseUrl = 'https://api.apixu.com/v1/forecast.json?key='
	apikey: ''
	cityLocation: "q=52.52,13.44"
	days: '1'

	getWeatherInfo: (done) ->
		url = baseUrl + @apikey + '&' + @cityLocation + '&days=' + @days
		allInfo =
			'currTemp': null
			'feelsLike': null
			'temps': null
			'description': null
			'forecast': null

		req.curlRequest url, (error, weatherinfo) =>
			if error then return done error
			if !weatherinfo?.current?.temp_c? then return done new Error 'Parsing Weather data error'
			allInfo.currTemp	= weatherinfo.current.temp_c + '°'
			allInfo.feelsLike	= weatherinfo.current.feelslike_c + '°'
			allInfo.temps		= allInfo.currTemp + " (" + allInfo.feelsLike + ")"
			allInfo.description = weatherinfo.current.condition.text
			allInfo.raining		= if weatherinfo.current.precip_mm > 1.2 then true else false
			allInfo.cloudy		= if weatherinfo.current.cloud > 60 then true else false
			allInfo.rainIcon	= @getIcon(allInfo.raining, allInfo.cloudy)
			allInfo.forecast	= @parseForecast(weatherinfo.forecast.forecastday)
			done null, allInfo


	getIcon: (raining, cloudy) ->
		iconName = if raining then 'rain'
		else if cloudy then 'cloudy'
		else 'sunny'
		return iconName


	parseForecast: (forecastdays) ->
		chance = if chance > 5 then chance + '%' else ''
		return {}
