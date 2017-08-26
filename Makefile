MAIN_EXECUTABLE = tests/sample/foo.exe

default:
	jbuilder build $(MAIN_EXECUTABLE)

install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall install

clean:
	jbuilder clean

run:
	@jbuilder build $(MAIN_EXECUTABLE) && _build/default/$(MAIN_EXECUTABLE)

.PHONY: default install uninstall reinstall clean examples
