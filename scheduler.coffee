async = require 'async'
_ = require 'underscore'
bart = new (require './vendors/Bart')
nextBus = new (require './vendors/Bus')
forecast = new (require './vendors/Weather')
output = require './lib/signPrinting'

refreshInterval = 10 * 1000
interval_count = 0

estimates = []


class DisplayObject
  constructor: (@name, @type, @default_iterations) ->
  Object.defineProperties @prototype,
    value:
      get: -> @val
      set: (@val) ->
    i:
      get: -> @iteration
      set: (@iteration) ->
    meta:
      get: -> @data
      set: (@data) ->


fruitvale = new DisplayObject 'Fruitvale', 'train', 3
twelveth = new DisplayObject '12th St.', 'train', 3
O = new DisplayObject 'oToCity', 'bus', 3
toBart = new DisplayObject '51aToBart', 'bus', 2
toOakland = new DisplayObject '51aToOakland', 'bus', 2
time = new DisplayObject 'timeAndWeather', 'weather', 8
weather = new DisplayObject 'WeatherIcon', 'weather', 8


routes = [
  fruitvale
  twelveth
  O
  toBart
  toOakland
  time
  time
  weather
]


# output pre-text to display
output.printString ' -- GETTING FIRST SCHEDULE -- ', null, () ->

setInterval ( ->
  d = new Date()
  commuteTime = d.getHours() is 7 or (d.getHours() is 8 and d.getMinutes() < 30)
  sleepTime = 1 <= d.getHours() <= 5
  nightWeekend = (d.getDay() is 6) or (d.getDay() is 0) or d.getHours() > 18

  if sleepTime
    output.printString ["It's late... ", 'Go back to sleep'], null, () ->

  # remove the O bus from the schedule
  if nightWeekend and routes[interval_count].name is 'oToCity'
    ++interval_count

  if commuteTime and not nightWeekend
    getCommuteEstimate (estimate) ->
      #console.log estimate
      output.printString estimate, null, () ->

  else
    getArrivalEstimate routes[interval_count], (estimate) ->
      if routes[interval_count].name is 'WeatherIcon' and routes[interval_count].meta
        output.printString estimate, routes[interval_count].meta, () ->
      else
        output.printString estimate, null, () ->
    if interval_count > (routes.length - 2) then interval_count = 0
    else ++interval_count

), refreshInterval



getArrivalEstimate = (displayObject, done) ->
  #skipped api call based on iterations
  if displayObject.value and displayObject.i
    displayObject.i--
    #update the time, but not the weather info
    if displayObject.type is 'weather'
      time = formatTime()
      if displayObject.name is 'timeAndWeather'
        displayObject.value = ['Alameda', time + "  " + displayObject.meta]
      else
        displayObject.value = time
    return done displayObject.value
  else
    displayObject.i = displayObject.default_iterations

  if displayObject.type is 'train'
    bart.getCityTrains displayObject.name, (error, info) ->
      if error
        done error.message
      else if info.error
        done [info.station, info.error]
      else
        line1 = displayObject.name + ' BART'
        times = (estObj.est for estObj in info.estimates)
        flattenedTimes = _.map (_.flatten times), (time) -> if time is 'Leaving' then 0 else parseInt time
        sortedTimes = flattenedTimes.sort (a, b) -> a - b
        if sortedTimes.length is 1
          line2 =  "#{sortedTimes[0]}min"
        else if sortedTimes.length is 2
          line2 = "#{sortedTimes[0]}min & #{sortedTimes[1]}min"
        else
          line2 = _.map sortedTimes, (time) -> " #{time}min"
        displayObject.value = [line1, line2]
        done displayObject.value

  else if displayObject.type is 'weather'
    time = formatTime()
    if displayObject.name is 'timeAndWeather'
      forecast.getCurrentTemp (error, temp) ->
        if error then return done "ERROR: #{error}"
        displayObject.meta = temp
        displayObject.value = ['Alameda', time + "  " + temp]
        done displayObject.value
    else
      forecast.getChanceOfRain true, (error, rainIcon) ->
        if error then return done "ERROR: #{error}"
        displayObject.meta = rainIcon
        displayObject.value = time
        done displayObject.value

  else if displayObject.type is 'bus'
    nextBus.getRouteInfo displayObject.name, (error, info) ->
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
        displayObject.value = [line1, line2]
        done displayObject.value

  else
    done "THIS WASN'T EXPECTED: #{displayObject}"


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
  suffex = if (hour >= 12) then "PM" else "AM"
  hour -= 12 if hour > 12
  #if 00 then it is 12 am
  hour = 12 if hour is 0
  minutes = ("00" + d.getMinutes()).slice -2
  return "#{hour}:#{minutes}#{suffex}"