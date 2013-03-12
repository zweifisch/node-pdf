fs = require 'fs'
path = require 'path'
{spawn} = require 'child_process'
{EventEmitter} = require 'events'
temp = require 'temp'
hogan = require 'hogan.js'

class XeLatex extends EventEmitter

	constructor: (@outputDirectory)->
		@output = ''

	process :(file)->
		xelatex = spawn 'xelatex', ['-interaction','nonstopmode','-output-directory',@outputDirectory,file]
		xelatex.on 'exit', (code)=>
			if code is 0
				filename = path.basename file, '.tex'
				@emit 'done',path.join @outputDirectory,"#{filename}.pdf"
			else
				@emit 'error',new Error "xelatex exits with #{code}\n#{@output}"
		xelatex.stdout.on 'data', (data)=>
			@output += data.toString()


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

cachedTemplates = {}

render = (source,data,callback)->

	if source not of cachedTemplates
		fs.readFile source,'utf-8',(err,sourceContent)=>
			renderFromTemplate (cachedTemplates[source] = hogan.compile sourceContent),data,callback
	else
		renderFromTemplate cachedTemplates[source],data,callback

renderFromTemplate = (template,data,callback)->

	temp.mkdir 'xelatex',(err,dirPath)->

		tex = template.render data
		fs.writeFile path.join(dirPath,'output.tex'),tex,->

			xelatex = new XeLatex dirPath
			xelatex.process path.join(dirPath,'output.tex')

			xelatex.on 'done',(path)->
				readStream = fs.createReadStream path
				readStream.on 'end',->
					rmdir dirPath,->
				callback null,readStream

			xelatex.on 'error',(err)->
				callback err,tex


module.exports =
	XeLatex: XeLatex
	render: render
