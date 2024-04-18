all: clean fun-facts init-job

fun-facts:
	@echo "Creating compiled builds in ./artifacts"
	@env GOOS=darwin GOARCH=amd64 go build  -o ./artifacts/osx/${BINARY} -v .
	@env GOOS=linux GOARCH=amd64 go build -ldflags '-linkmode external -extldflags "-static"' -o ./artifacts/linux/${BINARY} -v .
	@env GOOS=windows GOARCH=amd64 go build -o ./artifacts/windows/${BINARY} -v .
	@ls -lR ./artifacts

.PHONY: init-job
init-job:
	@echo "Adding init-job to zip file"
	@zip artifacts/init-job init-job/*

clean:
	@echo "clearing ./artifacts"
	@rm -rf ./artifacts