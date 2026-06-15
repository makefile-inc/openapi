include $(CURDIR)/makefile-common/include.mk.inc openapi.mk

test/tmp-openapi:
	@mkdir -p tmp-openapi/

test/download/and/convert: export SPEC_URL = https://raw.githubusercontent.com/moby/moby/refs/heads/master/api/swagger.yaml
test/download/and/convert: export OUT_PATH = tmp-openapi/v2.json
test/download/and/convert: export INPUT_SPEC = tmp-openapi/v2.json
test/download/and/convert: export OUT_SPEC_PATH = tmp-openapi/v3.json
test/download/and/convert: test/tmp-openapi openapi/update/spec openapi/convert/to/v3