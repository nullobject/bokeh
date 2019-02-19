.PHONY: clean lint publish-npm release test

test:
	@npx jest

lint:
	@npx standard "src/**/*.js"

release: publish-npm

publish-npm:
	@npm publish

clean:
	@rm -rf dst node_modules
