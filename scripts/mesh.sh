#!/bin/sh

#load configuration

# ucitrack
init=$(uci get ucitrack.@mesh[0].init)

if [ -z "$init" ];
then
    init=$(uci get mesh.@mesh[0].init)
    affects=$(uci get mesh.@network[0].affects)

    uci add ucitrack mesh
    uci set ucitrack.@mesh[0].init=${init}
    uci add_list ucitrack.@network[0].affects=${affects}
    uci commit ucitrack
fi

# luci (theme & language)
lang=$(uci get mesh.@core[0].lang)
media=$(uci get mesh.@core[0].mediaurlbase)
uci set luci.@core[0].lang=${lang}
uci set luci.@core[0].mediaurlbase=${media}
uci commit luci


