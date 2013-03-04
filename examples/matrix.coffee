fs = require 'fs'
{render} = require '../index'

data =
	title: 'Matrix'

render './matrix.tex', data, (err,rs)->
	if err
		console.log err
	else
		ws = fs.createWriteStream './output.pdf'
		rs.pipe ws
