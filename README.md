# node-pdf

pdf generation using mustache and xelatex

## usage

```sh
npm install node-pdf
```

```coffeescript
fs = require 'fs'
{render} = require 'node-pdf'

data =
	title: 'Matrix'

render './matrix.tex', data, (err,rs)->
	if err
		console.log err
	else
		ws = fs.createWriteStream './output.pdf'
		rs.pipe ws
```
