
SCRIPT=tecmint_monitor.sh
SCRIPT_OUT=tecmint_monitor
BINPREFIX=/usr/local/bin

default: install

install:
	@echo "Installing '$(SCRIPT)' ..."
	@chmod 775 "$(SCRIPT)"
	@cp -v "$(SCRIPT)" "$(BINPREFIX)/$(SCRIPT_OUT)"

uninstall:
	@echo "... uninstalling '$(SCRIPT_OUT)'"
	@rm -fv "$(BINPREFIX)/$(SCRIPT_OUT)"
