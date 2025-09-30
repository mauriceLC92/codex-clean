.PHONY: build run clean rebuild

build:
	./build-app.sh

run:
	open "build/Screenshot Sweeper.app"

clean:
	rm -rf .build build

rebuild: clean build