OPENAPI_CONVERTER_VERSION = v1.0.5

##@ Openapi

openapi/update/spec: check/installed/curl install/yq ## Download spec and convert to json
	##~ SPEC_URL=URL - URL to download spec 
	##~ OUT_PATH=PATH - output file
	@if [ -z "$$SPEC_URL" ]; then \
		echo -e "${RED_COLOR}Spec url not passed with env SPEC_URL${NO_COLOR}"; \
		exit 1; \
	fi; \
	if [ -z "$$OUT_PATH" ]; then \
		echo -e "${RED_COLOR}Out spec file not passed with env OUT_PATH${NO_COLOR}"; \
		exit 1; \
	fi; \
	dir_path="$$(dirname "$$OUT_PATH")"; \
	if ! dir_path="$$(realpath "$$dir_path")"; then \
		echo -e "${RED_COLOR}Cannot get real path for $$OUT_PATH${NO_COLOR}"; \
		exit 1; \
	fi; \
	if [ ! -d "$$dir_path" ]; then \
		echo -e "${RED_COLOR}$$dir_path out put dir is not exists${NO_COLOR}"; \
		exit 1; \
	fi; \
	set -Eeuo pipefail; \
	yaml_tmp="$$(mktemp)"; \
	curl -sSfLo "$$yaml_tmp" "$$SPEC_URL"; \
	cat "$$yaml_tmp" | "$(YQ_BIN_FULL)" -o=json -r . > "$(OUT_PATH)"

openapi/convert/to/v3: check/installed/docker check/installed/curl ## Convert opeanapi spec v2 to v3
	##~ INPUT_SPEC=PATH - Path to v2 spec 
	##~ OUT_SPEC_PATH=PATH - Output v3 spec file
	@if [ -z "$$INPUT_SPEC" ]; then \
		echo -e "${RED_COLOR}Input spec path not passed with env INPUT_SPEC${NO_COLOR}"; \
		exit 1; \
	fi; \
	if [ ! -f "$$INPUT_SPEC" ]; then \
		echo -e "${RED_COLOR}Input spec $$INPUT_SPEC is not file${NO_COLOR}"; \
		exit 1; \
	fi; \
	if [ -z "$$OUT_SPEC_PATH" ]; then \
		echo -e "${RED_COLOR}Out spec path not passed with env OUT_SPEC_PATH${NO_COLOR}"; \
		exit 1; \
	fi; \
	dir_path="$$(dirname "$$OUT_SPEC_PATH")"; \
	if ! dir_path="$$(realpath "$$dir_path")"; then \
		echo -e "${RED_COLOR}Cannot get real path for $$OUT_SPEC_PATH${NO_COLOR}"; \
		exit 1; \
	fi; \
	if [ ! -d "$$dir_path" ]; then \
		echo -e "${RED_COLOR}$$dir_path out put dir is not exists${NO_COLOR}"; \
		exit 1; \
	fi; \
	if ! cid="$$(docker run --rm -d -p 26080:8080 --name swagger-converter swaggerapi/swagger-converter:$(OPENAPI_CONVERTER_VERSION))"; then \
		echo -e "${RED}Converter container should not start${NO_COLOR}"; \
		exit 1; \
	fi; \
	echo "Converter container $$cid available on http://127.0.0.1:26080 Sleep 10s for init..."; \
	sleep 10; \
	is_error=""; \
	if ! curl -X POST \
		--fail \
		--data "@$(INPUT_SPEC)" \
		-H "Content-Type: application/yaml" \
		-H 'Accept: application/json' \
		http://127.0.0.1:26080/api/convert > $(OUT_SPEC_PATH) ; \
	then \
		is_error="true"; \
		echo -e "${RED}Convert failed${NO_COLOR}"; \
	fi; \
	echo "Stop converter container $$cid ..."; \
	if ! docker stop "$$cid"; then \
		is_error="true"; \
		echo -e "${RED}Container $$cid was not stopped!${NO_COLOR}"; \
	fi; \
	if [ "$$is_error" = "true" ]; then \
		exit 1; \
	fi

_OPENAPI_ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

openapi/gitignore: export GITIGNORES_TO_CHECK = $(_OPENAPI_ROOT_DIR)/makefile-common/.gitignore
openapi/gitignore: check/common/gitignore ## Check that .gitignore up to date with makefile/common