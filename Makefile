all: clean fun-facts package init-job

fun-facts:
	@echo "Creating compiled builds in ./artifacts"
	@env GOOS=darwin GOARCH=amd64 go build  -o ./artifacts/osx/${BINARY} -v .
	@env GOOS=linux GOARCH=amd64 go build -ldflags '-linkmode external -extldflags "-static"' -o ./artifacts/linux/${BINARY} -v .
	@env GOOS=windows GOARCH=amd64 go build -o ./artifacts/windows/${BINARY} -v .
	@ls -lR ./artifacts

package:
	@echo "Creating a deb package"
	@mkdir -p ./artifacts/package
	@mkdir -p ./artifacts/package/usr/bin
	@mkdir -p ./artifacts/package/lib/systemd/system
	@mkdir -p ./artifacts/package/DEBIAN
	@mkdir -p ./artifacts/package/var/funfacts
	@cp ./artifacts/linux/fun-facts ./artifacts/package/usr/bin
	@cp ./systemd/funfacts.service ./artifacts/package/lib/systemd/system/
	@cp ./systemd/control ./artifacts/package/DEBIAN/control
	@cp ./systemd/postinst ./artifacts/package/DEBIAN/postinst
	@cp ./systemd/postinst ./artifacts/package/DEBIAN/postinst
	@cp -r ./static  ./artifacts/package/var/funfacts
	@dpkg --build ./artifacts/package

.PHONY: init-job
init-job:
	@echo "Adding init-job to zip file"
	@zip artifacts/init-job init-job/*

clean:
	@echo "Clearing ./artifacts"
	@rm -rf ./artifacts