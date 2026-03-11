FROM ghcr.io/red40-development/luacheck:latest

RUN mkdir -p /luacheck-fivem
ADD . /luacheck-fivem/
RUN chmod +x /luacheck-fivem/.docker/entrypoint.sh
ENTRYPOINT ["/luacheck-fivem/.docker/entrypoint.sh"]
