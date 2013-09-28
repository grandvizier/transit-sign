fs = require 'fs'
LineByLineReader = require "line-by-line"

module.exports = class Font

	glyphs = []
	mainGlyphs = "lib/charmap.simpleglyphs"

	constructor: ->
		@loadGlyphs (error, @glyphs) ->


	loadGlyphs: (done) ->
		@glyphs = []
		glyph = {}
		lr = new LineByLineReader(mainGlyphs)
		lr.on "error", (error) ->
			console.log '  ooops ', error
			done error
		lr.on "end", () =>
			done null, @glyphs

		lr.on "line", (line) =>

			#start a new glyph
			if m = line.match /(\d+) (\d+) (\d+) (.)/
				glyph = {}
				glyph.charCode = m[1]
				glyph.padding  = m[2]
				glyph.height   = m[3]
				glyph.char     = m[4]
				glyph.bitmap   = []
			else if (line.replace(/^\s\s*/, "").replace /\s\s*$/, "") is ''
				@glyphs[glyph.charCode] = glyph
			else
				glyph.bitmap.push (line.replace(/^\s\s*/, "").replace /\s\s*$/, "") 
				glyph.width = line.length


	getCharWidth: (byte) =>
		#console.log "   #{byte}", @glyphs[byte]?.width
		return @glyphs[byte]?.width ? 0

	getCharBitmap: (byte, row) =>
		glyph = @glyphs[byte]
		unless glyph 
			console.log '  returning 0 for ', byte
			return '0'
		if glyph.height is '7' 
			#console.log '  returning', glyph.bitmap[row]
			return glyph.bitmap[row]
		else 
			bitmap = ''
			if (7 - glyph.height) > row
				shift = 0
				while shift < glyph.width
					bitmap += '0'
					shift++
			else 
				rowShift = row - (7 - glyph.height)
				bitmap = glyph.bitmap[rowShift]
			return  bitmap

