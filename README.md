# openapi
Makefiles includes for generations client and servers and convertions openapi specs.

## Deps

This suit uses https://github.com/makefile-inc/common suit.

## Install

### Manual

You can copy all files in your own repo (for example in subdir `makefile-openapi`) 
and include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-openapi/include.mk.inc
```

### As submodule

Add submodule:

```bash
git submodule add git@github.com:makefile-inc/openapi.git makefile-openapi
```

Checkout to target wersion:

```
pushd .
cd makefile-openapi
git fetch -a && git checkout v0.1.0 && git pull
popd
```

Include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-openapi/include.mk.inc
```

## Targets

- `openapi/update/spec` - download spec and convert to json
  Params:
  - SPEC_URL - url to to download openapi spec
  - OUT_PATH - path to output spec
  Example:
  ```bash
  make openapi/update/spec SPEC_URL=https://raw.githubusercontent.com/moby/moby/refs/heads/master/api/swagger.yaml OUT_PATH=tmp-openapi/v2-1.json
  ```
- `openapi/convert/to/v3` - convert v2 spec to v3. Uses `swaggerapi/swagger-converter` docker image for converting. 
  Params:
  - INPUT_SPEC - file with v2 spec
  - OUT_SPEC_PATH - file to out v3 spec
  Example:
  ```bash
  make openapi/convert/to/v3 INPUT_SPEC=tmp-openapi/v2-1.json OUT_SPEC_PATH=tmp-openapi/v3-1.json
  ```
- `openapi/check/gitignore` - Check that .gitignore up to date with makefile-inc/common
  Userfull for check up to date root .gitignore with makefile-inc/common during update.

### Example

You can create your own target for one task regenerate spec like:

```Makefile
include $(CURDIR)/makefile-openapi/include.mk.inc
openapi/dir:
	@mkdir -p openapi
generate/openapi: export SPEC_URL = https://raw.githubusercontent.com/moby/moby/refs/heads/master/api/swagger.yaml
generate/openapi: export OUT_PATH = openapi/v2.json
generate/openapi: export INPUT_SPEC = openapi/v2.json
generate/openapi: export OUT_PATH = openapi/v3.json
generate/openapi: openapi/dir openapi/update/spec openapi/convert/to/v3
```