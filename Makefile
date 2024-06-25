.PHONY: image
image:
	@docker build --build-arg PACKS="st2" \
		-t st2packs:latest .

all:
	image
