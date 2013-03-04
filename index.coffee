fs = require 'fs'
path = require 'path'
{spawn} = require 'child_process'
{EventEmitter} = require 'events'
temp = require 'temp'
mu = require 'mu2'

class XeLatex extends EventEmitter

	constructor: (@outputDirectory)->

	process :(file)->
		xelatex = spawn 'xelatex', ['-interaction','nonstopmode','-output-directory',@outputDirectory,file]
		xelatex.on 'exit', (code)=>
			if code is 0
				filename = path.basename file, '.tex'
				@emit 'done',path.join @outputDirectory,"#{filename}.pdf"
			else
				@emit 'error',new Error "xelatex exits with #{code}"


rmdir = (dir,callback) ->
	fs.readdir dir,(err,files)->
		if err
			return callback err
		removedFiles = 0
		for filename in files
			file = path.join dir, filename
			fs.unlink file,->
				removedFiles += 1
				if removedFiles is files.length
					fs.rmdir dir,callback


render = (source,data,callback)->

	rs = mu.compileAndRender source, data

	temp.mkdir 'xelatex', (err, dirPath)->

		ws = fs.createWriteStream path.join(dirPath, 'output.tex')
		rs.pipe ws
		ws.on 'close',->

			xelatex = new XeLatex dirPath
			xelatex.process path.join(dirPath, 'output.tex')

			xelatex.on 'done', (path)->
				readStream = fs.createReadStream path
				readStream.on 'end',->
					rmdir dirPath, ->
				callback null,readStream

			xelatex.on 'error', (err)->
				callback err


module.exports =
	XeLatex: XeLatex
	render: render
