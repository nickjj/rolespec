# RoleSpec Makefile: install, uninstall and test RoleSpec scripts
# Copyright (C) 2014 Nick Janetakis <nick.janetakis@gmail.com>


PREFIX="/usr/local"
BIN_DIR="${PREFIX}/bin"
LIB_DIR="${PREFIX}/lib/rolespec"


install:
	@echo "Installing RoleSpec scripts in ${BIN_DIR} ..."
	@test -d ${BIN_DIR} || mkdir -p ${BIN_DIR}
	@cp bin/rolespec ${BIN_DIR}/rolespec
	@echo "Installing RoleSpec libs in ${LIB_DIR} ..."
	@test -d {$LIB_DIR} || mkdir -p ${LIB_DIR}
	@cp VERSION ${LIB_DIR}
	@cp -r lib/* ${LIB_DIR}

clean:
	@echo "Cleaning up RoleSpec scripts ..."
	@rm -rf ${BIN_DIR}/rolespec
	@echo "Cleaning up RoleSpec libs ..."
	@rm -rf ${LIB_DIR}

test:
	@echo "Testing RoleSpec ..."
	tests/test-cli
