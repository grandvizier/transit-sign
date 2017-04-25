fs = require 'fs'
async = require 'async'
_ = require 'underscore'
logger = require 'winston'
forecast = new (require './vendors/Weather')
output = require './lib/signPrinting'


configData = null
minuteInterval = 60 * 1000
refreshInterval = 10 * 1000
interval_count = 0

estimates = []


class DisplayObject
  constructor: (@name, @type) ->
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


updateConfig = () ->
  fs.readFile 'config.json', (err, data) ->
    if err?
      logger.error 'A config file is required with at least a weather key. See README.'
      throw err
    configData = JSON.parse(data)
    forecast.apikey = configData.weather.key


time       = new DisplayObject 'timeAndWeather', 'weather'
prediction = new DisplayObject 'WeatherIcon', 'weather'


displays = [
  time
  prediction
]
city = "Berlin"
bday = null
weatherData = null
lastCheck = null
updateConfig()


# output pre-text to display
output.printString ' -- LOADING UP DATA -- ', null, () ->


setInterval ( ->
  d = new Date()
  sleepTime = 1 <= d.getHours() <= 5
  updateConfig()

  if sleepTime
    bday = checkBirthdays(d, configData.birthdays)
    output.printString ["It's late... #{formatTime()}", 'Go back to sleep'], null, () ->

  else if bday?
      output.printString ["Happy Birthday", bday.name], null, () ->

  else
    getPrintContent displays[interval_count], (content) ->
      if displays[interval_count].name is 'WeatherIcon' and displays[interval_count].meta
        output.printString content, displays[interval_count].meta, () ->
      else
        output.printString content, null, () ->
    if interval_count > (displays.length - 2) then interval_count = 0
    else ++interval_count

), refreshInterval



getPrintContent = (displayObject, done) ->
  time = formatTime()

  if displayObject.type is 'weather'
    getWeatherData (error, data) ->
      if error then return done "ERROR: #{error}"
      displayObject.meta = data.rainIcon
      if displayObject.name is 'WeatherIcon'
        displayObject.value = [time, data.description]
      else
        displayObject.value = [city, "#{time}  #{data.temps}"]
      return done displayObject.value

  else
    done "THIS WASN'T EXPECTED: #{displayObject}"


getWeatherData = (done) ->
  d = new Date()
  if !lastCheck?
      logger.debug 'setting lastCheck time to a time in the past'
      lastCheck = d.getTime() - (configData.weather.apiFrequency * minuteInterval)
  if (d.getTime() - lastCheck) >= (configData.weather.apiFrequency * minuteInterval)
    logger.info "checking weather api"
    forecast.getWeatherInfo (error, freshData) ->
      lastCheck = d.getTime()  # even if there was an error, don't check again till next interval
      if error then return done "ERROR: #{error}"
      weatherData = freshData
      done null, weatherData
  else
    logger.debug "reusing weather data"
    done null, weatherData


formatTime = () ->
  d = new Date()
  hour = d.getHours()
  minutes = ("00" + d.getMinutes()).slice -2
  return "#{hour}:#{minutes}"


checkBirthdays = (currentDate, birthdays) ->
  (if bd.day is currentDate.getDate() and bd.month is (currentDate.getMonth() + 1)
    (congrat or congrat = [])
  else []).push bd for bd in birthdays
  return congrat?[0]
