req = require '../lib/requests'
_ = require 'underscore'

module.exports = class Bus

	#used to get info - but we already know which buses we want 
	agencyUrl = "http://webservices.nextbus.com/service/publicXMLFeed?command=agencyList"
	acRouteList = "http://webservices.nextbus.com/service/publicXMLFeed?command=routeList&a=actransit"
	muniRouteList = "http://webservices.nextbus.com/service/publicXMLFeed?command=routeList&a=sf-muni"

	oRoute = 'http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=actransit&r=O'
	wRoute = 'http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=actransit&r=W'
	_51ARoute = 'http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=actransit&r=51A'

	acPredictionUrl = 'http://webservices.nextbus.com/service/publicXMLFeed?command=predictions&a=actransit'
	predictionUrls = 
		'oToCity': 		"#{acPredictionUrl}&r=O&s=0103270" 
		'wToCity': 		"#{acPredictionUrl}&r=W&s=0101380"  
		'51aToBart':	"#{acPredictionUrl}&r=51A&s=0103280"
		'51aToOakland':	"#{acPredictionUrl}&r=51A&s=0103270"


	getRouteInfo: (route, done) ->
		busInfo = type: 'bus'
		req.curlRequest predictionUrls[route], (error, info) =>
			if error then  busInfo.error = true; return done error, busInfo
			estimates = null
			busInfo.route = info.body.predictions[0].$.routeTitle
			busInfo.stop = info.body.predictions[0].$.stopTitle
			if info.body.predictions[0].direction
				busInfo.direction = info.body.predictions[0].direction[0].$.title.replace /BART/, ""
				estimates = _.map info.body.predictions[0].direction[0].prediction, (est) -> est.$.minutes
				busInfo.estimates = estimates
				done null, busInfo
			else
				msg = info?.body?.predictions?[0].message?[0].$?.text ? 'no message'
				busInfo.error = msg
				done new Error('404 No Bus Found: ' + msg), busInfo

