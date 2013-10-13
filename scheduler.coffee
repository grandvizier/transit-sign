async = require 'async'
_ = require 'underscore'
bart = new (require './vendors/Bart')
nextBus = new (require './vendors/Bus')
forecast = new (require './vendors/Weather')
output = require './lib/signPrinting' 

refreshInterval = 10 * 1000
interval_count = 0

estimates = []

routes = [
  'Fruitvale'
  '12th St.'
  'oToCity'
  '51aToBart'
  '51aToOakland'
  'weather'
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

  # remove the O bus from the schedule
  if nightWeekend and routes[interval_count] is 'oToCity'
    ++interval_count

  if commuteTime and not nightWeekend
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
        if sortedTimes.length is 1
          line2 =  "#{sortedTimes[0]}min"
        else if sortedTimes.length is 2
          line2 = "#{sortedTimes[0]}min & #{sortedTimes[1]}min"
        else
          line2 = _.map sortedTimes, (time) -> " #{time}min"
        estimates[routeArray[order]] = [line1, line2]
        done [line1, line2]

  else if routeArray[order] is 'weather'
    time = formatTime()
    forecast.getTempAndRain (error, tempAndRain) ->
      if error then return done "error: #{error}"
      info = ['Alameda', time + "  " + tempAndRain]
      estimates[routeArray[order]] = info
      done info

  else
    nextBus.getRouteInfo routeArray[order], (error, info) ->
      if error
        done error.message
      else if info.error
        done ["#{info.route}: #{info.stop} ", info.error]
      else
        line1 = info.route + ": " + info.direction
        if info.estimates.length is 1
          line2 =  "#{info.estimates[0]}min"
        else if info.estimates.length is 2
          line2 = "#{info.estimates[0]}min & #{info.estimates[1]}min"
        else
          line2 = _.map info.estimates, (est) -> " #{est}min"
        estimates[routeArray[order]] = [line1, line2]
        done [line1, line2]


getCommuteEstimate = (done) ->
  async.parallel 
    acOInfo: (next) ->
      nextBus.getRouteInfo 'oToCity', (error, info) =>
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




formatTime = () ->
  d = new Date()
  hour = d.getHours()
  suffex = if (hour >= 12) then "pm" else "am"
  hour = if (hour > 12) then hour - 12 else hour
  #if 00 then it is 12 am
  hour = if (hour is "00") then 12 else hour
  minutes = ("00" + d.getMinutes()).slice -2
  return "#{hour}:#{minutes}#{suffex}"