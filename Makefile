build: src
	elm make --output=www/assets/elm.js src/Main.elm

docker:
	docker run --rm -v $(CURDIR)/www:/usr/share/nginx/html -v $(CURDIR)/nginx.conf:/etc/nginx/nginx.conf:ro -p 8000:80 nginx
