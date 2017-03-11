async = require 'async'
_ = require 'underscore'
forecast = new (require './vendors/Weather')
output = require './lib/signPrinting'

try
  configData = require 'config.json'
catch error
  console.log 'A config file is required with a minimum of a weather key. See README.'

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


time = new DisplayObject 'timeAndWeather', 'weather', 8
weather = new DisplayObject 'WeatherIcon', 'weather', 8


routes = [
  time
  weather
]
city = "Berlin"

# output pre-text to display
output.printString ' -- GETTING FIRST SCHEDULE -- ', null, () ->
logger = require 'winston'

setInterval ( ->
  d = new Date()
  commuteTime = d.getHours() is 7 or (d.getHours() is 8 and d.getMinutes() < 30)
  sleepTime = 1 <= d.getHours() <= 5
  nightWeekend = (d.getDay() is 6) or (d.getDay() is 0) or d.getHours() > 18

  if sleepTime
    output.printString ["It's late... ", 'Go back to sleep'], null, () ->

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
        displayObject.value = [city, time + "  " + displayObject.meta]
      else
        displayObject.value = time
    return done displayObject.value
  else
    displayObject.i = displayObject.default_iterations

  if displayObject.type is 'weather'
    time = formatTime()
    forecast.getWeatherInfo (error, weatherData) ->
      if error then return done "ERROR: #{error}"
      logger.info weatherData
      displayObject.meta = weatherData.currTemp
      displayObject.meta = weatherData.rainIcon
      displayObject.value = [city, time + "  " + weatherData.feelsLike]
      displayObject.value = time
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