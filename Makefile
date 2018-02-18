INSTALL_ARGS := $(if $(PREFIX),--prefix stty$(PREFIX),)

default: normalize
	@jbuilder build @install

install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall reinstall

clean:
	@jbuilder clean

test: normalize
	@jbuilder runtest

normalize:
	@mkdir -p _build/default/test/{ounit,detection,alcotest}

.PHONY: default install uninstall reinstall clean test
