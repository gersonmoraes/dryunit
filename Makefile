
MAIN_EXECUTABLE = src/dryunit/dryunit.exe

EXECUTABLE_OUNIT = tests/ounit/main.exe
EXECUTABLE_ALCOTEST = tests/alcotest/main.exe
EXECUTABLE_CORE = tests/core/main.exe

default:
	jbuilder build $(MAIN_EXECUTABLE)

clean:
	jbuilder clean

run:
	@jbuilder build $(MAIN_EXECUTABLE) && _build/default/$(MAIN_EXECUTABLE)

run_ounit:
	@jbuilder build $(EXECUTABLE_OUNIT) && _build/default/$(EXECUTABLE_OUNIT)

run_alcotest:
	# jbuilder build @tests/alcotest/dryunit && jbuilder build $(EXECUTABLE_ALCOTEST) && _build/default/$(EXECUTABLE_ALCOTEST)
	rm -f _build/default/tests/alcotest/main.ml && jbuilder build $(EXECUTABLE_ALCOTEST) && _build/default/$(EXECUTABLE_ALCOTEST)

test_core:
	@jbuilder build $(EXECUTABLE_CORE) && _build/default/$(EXECUTABLE_CORE)

test: clean test_core
	@jbuilder runtest


install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall install


.PHONY: default install uninstall reinstall clean examples
