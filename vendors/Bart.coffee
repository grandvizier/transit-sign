req = require '../lib/requests'
_ = require 'underscore'

module.exports = class Bart

	# http://api.bart.gov/api/etd.aspx?cmd=etd&orig=RICH&key=MW9S-E7SL-26DU-VV8V

	api_key = 'MW9S-E7SL-26DU-VV8V'
	baseEtdUrl = 'http://api.bart.gov/api/etd.aspx?cmd=etd'
	stations = 
		Fruitvale: 'FTVL'
		'12th St.': '12TH'
		dalyCity: 'DALY'
		milbrae: 'MLBR'


	getCityTrains: (stationName, done) ->
		url = baseEtdUrl + "&orig=#{stations[stationName]}&key=#{api_key}"
		@getTrainsToCity url, done


	getTrainsToCity: (url, done) ->
		trainInfo = type: 'train'
		req.curlRequest url, (error, info) =>
			if error then return done error
			if info?.root?.station?.length
				trainInfo.station = info.root.station[0].name.toString()
				trainInfo.estimates = []
				_.each info.root.station[0].etd, (etd) =>
					if etd.abbreviation[0] is stations.dalyCity or etd.abbreviation[0] is stations.milbrae
						trainInfo.estimates.push 
							dest: etd.destination
							est: (_.map etd.estimate, (est) =>  est.minutes.toString())
				done null, trainInfo
			else
				trainInfo.error = true
				done new Error('no trains a commin'), trainInfo
