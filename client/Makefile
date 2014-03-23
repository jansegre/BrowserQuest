outdir := ../static/js

all:
	@#browserify -d --ig -e main | exorcist ../static/bundle.js.map > ../static/bundle.js
	@#browserify -d --ig -e main | minifyify --optimizer uglify | exorcist ../static/bundle.js.map > ../static/bundle.min.js
	@#browserify -d --ig -e main | uglifyjs - --in-source-map --source-map-include-sources | exorcist ../static/bundle.js.map > ../static/bundle.min.js
	@#browserify -d --ig -e main | uglifyjs - --in-source-map --source-map-include-sources > ../static/bundle.min.js
	@#browserify -d --ig -e main | uglifyjs - --in-source-map --source-map-include-sources > ../static/bundle.min.js
	browserify -d --ig -e main | exorcist $(outdir)/bundle.js.map > $(outdir)/bundle.js
	uglifyjs $(outdir)/bundle.js --in-source-map $(outdir)/bundle.js.map --source-map $(outdir)/bundle.min.js.map --source-map-root src --source-map-url bundle.min.js.map > $(outdir)/bundle.min.js
	browserify -d --ig -e mapworker | exorcist ../static/mapworker.js.map > ../static/mapworker.js
