
coffee:
	@coffee --compile --output lib src

coffee-watch:
	@coffee --watch --compile --output lib src

clean:
	@rm -rf ./lib
