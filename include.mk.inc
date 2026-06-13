_INC_MK_OPENAPI_ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include $(_INC_MK_OPENAPI_ROOT_DIR)/*.mk