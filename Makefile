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
	@mkdir -p _build/default/test/detection/{ounit,generic,alcotest}
	@mkdir -p _build/default/test/modifiers

.PHONY: default install uninstall reinstall clean test
