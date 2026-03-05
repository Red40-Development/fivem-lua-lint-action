FROM ghcr.io/illeniumstudios/luacheck:v1.1.1-fivem-lua-v1.3.1

RUN mkdir -p /luacheck-fivem
ADD . /luacheck-fivem/
RUN chmod +x /luacheck-fivem/.docker/entrypoint.sh
ENTRYPOINT ["/luacheck-fivem/.docker/entrypoint.sh"]
