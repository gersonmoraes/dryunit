MAIN_EXECUTABLE = tests/alcotest/main.exe
# MAIN_EXECUTABLE = tests/ounit/main.exe

EXECUTABLE_1 = tests/ounit/main.exe
EXECUTABLE_2 = tests/alcotest/main.exe

default:
	jbuilder build $(MAIN_EXECUTABLE)
clean:
	jbuilder clean

run:
	@jbuilder build $(MAIN_EXECUTABLE) && _build/default/$(MAIN_EXECUTABLE)

run1:
	@jbuilder build $(EXECUTABLE_1) && _build/default/$(EXECUTABLE_1)

run2:
	@jbuilder build $(EXECUTABLE_2) && _build/default/$(EXECUTABLE_2)

test:
	@jbuilder runtest


install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall install


.PHONY: default install uninstall reinstall clean examples
