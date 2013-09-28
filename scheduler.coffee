async = require 'async'
_ = require 'underscore'
bart = new (require './vendors/Bart')
nextBus = new (require './vendors/Bus')
output = require './lib/signPrinting' 

refreshInterval = 10 * 1000
interval_count = 0

estimates = []

routes = [
  'Fruitvale'
  '12th St.'
  'oToCity'
  'wToCity'
  '51aToBart'
  '51aToOakland'
]

nightWeekendRoutes = [
  'Fruitvale'
  '12th St.'
  '51aToBart'
  '51aToOakland'
]


# output pre-text to display
output.printString ' -- Getting first schedule -- ', () ->

setInterval ( ->
  d = new Date()
  commuteTime = d.getHours() is 7 or (d.getHours() is 8 and d.getMinutes() < 30)
  sleepTime = 1 <= d.getHours() <= 5
  nightWeekend = (d.getDay() is 6) or (d.getDay() is 0) or d.getHours() > 18

  if sleepTime
    output.printString ["It's late... ", 'Go back to sleep'], () ->

  else if nightWeekend
    getArrivalEstimate nightWeekendRoutes, interval_count, (estimate) ->
      # console.log ' * ', estimate
      output.printString estimate, () ->
    if interval_count > (nightWeekendRoutes.length - 2) then interval_count = 0
    else ++interval_count

  else if commuteTime
    getCommuteEstimate (estimate) -> 
      #console.log estimate
      output.printString estimate, () ->

  else
    getArrivalEstimate routes, interval_count, (estimate) ->
      # console.log ' * ', estimate
      output.printString estimate, () ->
    if interval_count > (routes.length - 2) then interval_count = 0 
    else ++interval_count

), refreshInterval



getArrivalEstimate = (routeArray, order, done) ->
  if estimates[routeArray[order]]
    console.log 'saving an api call'
    skippedApiCall = estimates[routeArray[order]]
    estimates[routeArray[order]] = null
    done skippedApiCall
  else if order < 2
    bart.getCityTrains routeArray[order], (error, info) ->
      if error
        done error.message
      else if info.error
        done [info.station, info.error]
      else
        line1 = routeArray[order] + ' BART'
        times = (estObj.est for estObj in info.estimates)
        flattenedTimes = _.map (_.flatten times), (time) -> if time is 'Leaving' then 0 else parseInt time
        sortedTimes = flattenedTimes.sort (a, b) -> a - b
        line2 = _.map sortedTimes, (time) -> " #{time}min"
        estimates[routeArray[order]] = [line1, line2]
        done [line1, line2]
  else
    nextBus.getRouteInfo routeArray[order], (error, info) ->
      if error
        done error.message
      else if info.error
        done ["#{info.route}: #{info.stop} ", info.error]
      else
        line1 = info.route + ": " + info.direction
        line2 = _.map info.estimates, (est) -> " #{est}min"
        estimates[routeArray[order]] = [line1, line2]
        done [line1, line2]


getCommuteEstimate = (done) ->
  async.parallel 
    acOInfo: (next) ->
      nextBus.getRouteInfo '51aToBart', (error, info) =>
        next null, info
    acWInfo: (next) ->
      nextBus.getRouteInfo 'wToCity', (error, info) =>
        next null, info
  , (error, results) ->
    oInfo = 'O: ' + results.acOInfo.error ? ''
    wInfo = 'W: ' + results.acWInfo.error ? ''
    if results.acOInfo.estimates
      oInfo = 'O: ' + results.acOInfo.estimates
    if results.acWInfo.estimates
      wInfo = 'W: ' + results.acWInfo.estimates
    done [oInfo, wInfo]




