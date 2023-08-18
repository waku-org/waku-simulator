BIN_DIR = bin/
CLI = bin/wakusim

build:
	go build -o $(CLI) main.go

clean:
	rm -rf $(CLI)