
EXECUTABLE_OUNIT = tests/ounit/main.exe
EXECUTABLE_ALCOTEST = tests/alcotest/main.exe
EXECUTABLE_CORE = tests/core/main.exe

default:
	jbuilder build $(MAIN_EXECUTABLE)

clean:
	@rm -rf .dryunit
	jbuilder clean

run_ounit:
	@jbuilder build $(EXECUTABLE_OUNIT) && _build/default/$(EXECUTABLE_OUNIT)

run_alcotest:
	@rm -f _build/default/tests/alcotest/main.ml && jbuilder build $(EXECUTABLE_ALCOTEST) && _build/default/$(EXECUTABLE_ALCOTEST)

test: clean
	@jbuilder runtest

install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall install


.PHONY: default install uninstall reinstall clean examples
