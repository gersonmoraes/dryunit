INSTALL_ARGS := $(if $(PREFIX),--prefix stty$(PREFIX),)

default:
	@jbuilder build @install

install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall reinstall

clean:
	@jbuilder clean

test:
	@#NOCOLORS=1 jbuilder runtest
	@jbuilder runtest


.PHONY: default install uninstall reinstall clean test
