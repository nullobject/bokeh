.PHONY: clean lint node_modules publish-npm test

node_modules:
	@npm install

test:
	@npx jest

lint:
	@npx standard "src/**/*.js"

publish-npm:
	@npm publish

clean:
	@rm -rf dst node_modules
