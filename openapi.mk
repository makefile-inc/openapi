OPENAPI_CONVERTER_VERSION = v1.0.5

##@ OpenAPI

openapi/update/spec: check/installed/curl install/yq ## Download spec and convert to json
	@##~ SPEC_URL=URL - URL to download spec 
	@##~ OUT_PATH=PATH - output file
	@${INCLUDE_ECHO} \
	if [ -z "$$SPEC_URL" ]; then \
		exit_with_err "Spec url not passed with env SPEC_URL"; \
	fi; \
	if [ -z "$$OUT_PATH" ]; then \
		exit_with_err "Out spec file not passed with env OUT_PATH"; \
	fi; \
	dir_path="$$(dirname "$$OUT_PATH")"; \
	if ! dir_path="$$(realpath "$$dir_path")"; then \
		exit_with_err "Cannot get real path for $$OUT_PATH"; \
	fi; \
	if [ ! -d "$$dir_path" ]; then \
		exit_with_err "$$dir_path out put dir is not exists"; \
	fi; \
	set -Eeuo pipefail; \
	yaml_tmp="$$(mktemp)"; \
	curl -sSfLo "$$yaml_tmp" "$$SPEC_URL"; \
	cat "$$yaml_tmp" | "$(YQ_BIN_FULL)" -o=json -r . > "$(OUT_PATH)"; \
	rm -f "$$yaml_tmp"

openapi/convert/to/v3: check/installed/docker check/installed/curl ## Convert opeanapi spec v2 to v3
	@##~ INPUT_SPEC=PATH - Path to v2 spec 
	@##~ OUT_SPEC_PATH=PATH - Output v3 spec file
	@${INCLUDE_ECHO} \
	if [ -z "$$INPUT_SPEC" ]; then \
		exit_with_err "Input spec path not passed with env INPUT_SPEC"; \
	fi; \
	if [ ! -f "$$INPUT_SPEC" ]; then \
		exit_with_err "Input spec $$INPUT_SPEC is not file"; \
	fi; \
	if [ -z "$$OUT_SPEC_PATH" ]; then \
		exit_with_err "Out spec path not passed with env OUT_SPEC_PATH"; \
	fi; \
	dir_path="$$(dirname "$$OUT_SPEC_PATH")"; \
	if ! dir_path="$$(realpath "$$dir_path")"; then \
		exit_with_err "Cannot get real path for $$OUT_SPEC_PATH"; \
	fi; \
	if [ ! -d "$$dir_path" ]; then \
		exit_with_err "$$dir_path out put dir is not exists"; \
		exit 1; \
	fi; \
	if ! cid="$$(docker run --rm -d -p 26080:8080 --name swagger-converter swaggerapi/swagger-converter:$(OPENAPI_CONVERTER_VERSION))"; then \
		exit_with_err "Converter container should not start"; \
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
		echo_err "Convert failed"; \
	fi; \
	echo "Stop converter container $$cid ..."; \
	if ! docker stop "$$cid"; then \
		is_error="true"; \
		echo_err "Container $$cid was not stopped!"; \
	fi; \
	if [ "$$is_error" = "true" ]; then \
		exit 1; \
	fi

_OPENAPI_ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

openapi/check/gitignore: export GITIGNORES_WITH_REQUIRED_RULES = $(_OPENAPI_ROOT_DIR)/makefile-common/.gitignore
openapi/check/gitignore: common/git/check/gitignore ## Check that .gitignore up to date with makefile-inc/common

.PHONY: openapi/update/spec openapi/convert/to/v3 openapi/check/gitignore