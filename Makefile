
EXECUTABLE_OUNIT = tests/ounit/main.exe
EXECUTABLE_ALCOTEST = tests/alcotest/main.exe
EXECUTABLE_ARGS = tests/args/main.exe
MAIN_EXECUTABLE = src/dryunit/dryunit.exe
BUILD_DIR = _build/default


default:
	@jbuilder build $(MAIN_EXECUTABLE)

clean:
	@rm -rf .dryunit
	jbuilder clean

run_ounit:
	@jbuilder build $(EXECUTABLE_OUNIT) && _build/default/$(EXECUTABLE_OUNIT)

run_args: clean
	@jbuilder build $(EXECUTABLE_ARGS) && _build/default/$(EXECUTABLE_ARGS)

build_args: clean
	@jbuilder build $(EXECUTABLE_ARGS)

run_alcotest:
	jbuilder build $(EXECUTABLE_ALCOTEST) && _build/default/$(EXECUTABLE_ALCOTEST)

test: clean
	@jbuilder runtest

install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall install

run: default
	@$(BUILD_DIR)/$(MAIN_EXECUTABLE) $(filter-out $@,$(MAKECMDGOALS))

%:
	@:

.PHONY: default install uninstall reinstall clean examples
