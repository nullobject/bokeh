name     = bokeh
status  := $(shell git status --porcelain)
version := $(shell git describe --tags)
regex   := "s/\([\"\']version[\"\'][[:space:]]*:[[:space:]]*\)\([\"\'].*[\"\']\)/\1\"$(version)\"/g"

.PHONY: bump changelog clean lint publish publish-npm production release test unit

# Builds a production version of libarary.
production: node_modules
	@node_modules/.bin/coffee -c -o dist src

test: unit lint

release: production test publish

publish: bump changelog publish-npm

unpublish: delete-tag unpublish-npm

clean:
	@rm -rf node_modules

node_modules:
	@npm install

# Runs the unit tests.
unit:
	@node_modules/.bin/mocha

# Runs jslint.
lint:
	@node_modules/.bin/jshint src

# Generates the API documentation.
doc:
	@node_modules/.bin/jsdoc -c jsdoc.config.json src README.md

# Bumps the version of the bower and npm packages.
bump:
	@sed -i "" $(regex) package.json

# Updates the changelog and tags the release.
changelog:
	@git changelog -t "v$(version)"
	@git add --all .
	@git release "v$(version)"

delete-tag:
	@git tag --delete "v$(version)"
	@git push --delete origin "v$(version)"

# Publishes the npm package.
publish-npm:
	@npm publish

unpublish-npm:
	@npm unpublish "$(name)@$(version)"
