#!/bin/sh -l
CONFIG_PATH=$3
LUACHECK_ARGS="--default-config $CONFIG_PATH $1"
LUACHECK_PATH="$2"
LUACHECK_CAPTURE_OUTFILE="$GITHUB_WORKSPACE/$4"
LUACHECK_EXIT_ON_WARN="$5"
EXTRA_LIBS="$6"

# extra luacheck definitions (without runtime Node/Yarn)
if [ -n "$EXTRA_LIBS" ]; then
  GENERATED_TEMPLATE_PATH="/luacheck-fivem/.luacheckrc.generated.template"
  if [ -f "$GENERATED_TEMPLATE_PATH" ]; then
    TEMP_CONFIG_PATH="/tmp/luacheckrc.default.$$"
    ESCAPED_EXTRA=$(printf '%s' "$EXTRA_LIBS" | sed 's/[\/&]/\\&/g')
    sed "s/%%EXTRA%%/+${ESCAPED_EXTRA}/g" "$GENERATED_TEMPLATE_PATH" > "$TEMP_CONFIG_PATH"
    CONFIG_PATH="$TEMP_CONFIG_PATH"
    LUACHECK_ARGS="--default-config $CONFIG_PATH $1"
  fi
fi

EXIT_CODE=0

echo "Args => 1: $1, 2: $2, 3: $3, 4: $4, 5: $5, 6: $6, 7: $7"

cd $GITHUB_WORKSPACE

echo "outfile => $LUACHECK_CAPTURE_OUTFILE"

if [ -n "$4" ]; then
  echo "exec => luacheck $LUACHECK_ARGS $LUACHECK_PATH 2>>$LUACHECK_CAPTURE_OUTFILE"
  luacheck --operators "+=" $LUACHECK_ARGS $LUACHECK_PATH >$LUACHECK_CAPTURE_OUTFILE 2>&1 || true

  echo "exec => luacheck $LUACHECK_ARGS --formatter default $LUACHECK_PATH"
  luacheck --operators "+=" $LUACHECK_ARGS --formatter default $LUACHECK_PATH || EXIT_CODE=$?
else
  echo "exec => luacheck $LUACHECK_ARGS $LUACHECK_PATH"
  luacheck --operators "+=" $LUACHECK_ARGS $LUACHECK_PATH || EXIT_CODE=$?
fi

echo "exit => $EXIT_CODE"
if [ "$LUACHECK_EXIT_ON_WARN" = true ]; then
  exit $EXIT_CODE
elif [ $EXIT_CODE -ge 2 ]; then
  exit $EXIT_CODE
fi
