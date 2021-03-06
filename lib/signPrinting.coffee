_ = require 'underscore'
logger = require 'winston'
childProcess = require "child_process"
font = new (require './font.coffee')

logger.add logger.transports.File,
  filename: 'printingLog.log'
  tailable: true
  json: false
  maxsize: 40500
  maxFiles: 2

module.exports.printString = (arrayToPrint, icon, done) ->
	pathToApi = "./vendors/LEDapi.pl"
	logger.info "To Print:", arrayToPrint
	_renderText arrayToPrint, (error, strToPrint) =>
		if error
			output = childProcess.exec("#{pathToApi} '#{error.message}'", (error, stdout, stderr) ->
			  logger.error 'FAILED TO CONVERT AND PRINT:', error.stack  if error
			)
			output.on 'exit', (code) -> done()
		else
			output = childProcess.exec("#{pathToApi} '#{strToPrint}' #{icon}", (error, stdout, stderr) ->
			  logger.error 'FAILED TO PRINT:', error.stack  if error
			)
			output.on 'exit', (code) -> done()


module.exports._renderText = _renderText = (textArray, done) ->
	unless textArray then return done new Error 'NO MESSAGE TO SEND'
	if typeof(textArray) is 'string' then return done null, textArray
	if textArray.length is not 2 then return done new Error 'SENT TOO MUCH TO PRINT: ' + textArray

	line = textArray[0]
	line_pics =  _.map textArray, (line) ->
		totalLineSize = 96
		str = line.toString().replace /^\s+|\s+$/g, ""
		line_width = 0
		bytes = []
		i = 0

		while i < str.length
		  bytes.push str.charCodeAt(i)
		  line_width += 1 + font.getCharWidth str.charCodeAt(i)
		  ++i


		lineShift_pre = if line_width >= totalLineSize then 0 else Math.round((totalLineSize - line_width) / 2)
		lineShift_post = unless lineShift_pre then 0 else totalLineSize - line_width - lineShift_pre

		lineBits = ''
		bitRow = ''
		lineFluff_pre = ''
		lineFluff_post = ''
		num = 1
		while num <= totalLineSize
		  lineBits += "0"
		  num++
		num = 1
		while num <= lineShift_pre
		  lineFluff_pre += "0"
		  num++
		num = 1
		while num <= lineShift_post
		  lineFluff_post += "0"
		  num++

		row = 0
		while row < 7
		  bitRow += lineFluff_pre
		  bitRow += font.getCharBitmap(c, row) + '0' for c in bytes
		  bitRow += lineFluff_post
		  lineBits += bitRow.substring 0, totalLineSize
		  bitRow =''
		  row++

		 return lineBits


	done null, line_pics.join ''

