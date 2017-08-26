#MAIN_EXECUTABLE = tests/sample/foo.exe
#MAIN_EXECUTABLE = tests/detection/main.exe
MAIN_EXECUTABLE = tests/alcotest/main.exe

default:
	jbuilder build $(MAIN_EXECUTABLE)
clean:
	jbuilder clean

run:
	@jbuilder build $(MAIN_EXECUTABLE) && _build/default/$(MAIN_EXECUTABLE)

test:
	@jbuilder runtest


install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall install


.PHONY: default install uninstall reinstall clean examples
