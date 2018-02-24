%%--------------------------------------------------------------------
%% Copyright (c) 2013-2018 EMQ Enterprise, Inc. (http://emqtt.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_mod_subscription).

-author("Feng Lee <feng@emqtt.io>").

-behaviour(emqx_gen_mod).

-include_lib("emqx/include/emqx.hrl").

-include_lib("emqx/include/emqx_mqtt.hrl").

-export([load/1, on_client_connected/3, unload/1]).

-define(TAB, ?MODULE).

%%--------------------------------------------------------------------
%% Load/Unload Hook
%%--------------------------------------------------------------------

load(Topics) ->
    emqx:hook('client.connected', fun ?MODULE:on_client_connected/3, [Topics]).

on_client_connected(?CONNACK_ACCEPT, Client = #mqtt_client{client_id  = ClientId,
                                                           client_pid = ClientPid,
                                                           username   = Username}, Topics) ->

    Replace = fun(Topic) -> rep(<<"%u">>, Username, rep(<<"%c">>, ClientId, Topic)) end,
    TopicTable = [{Replace(Topic), Qos} || {Topic, Qos} <- Topics],
    ClientPid ! {subscribe, TopicTable},
    {ok, Client};

on_client_connected(_ConnAck, _Client, _State) ->
    ok.

unload(_) ->
    emqx:unhook('client.connected', fun ?MODULE:on_client_connected/3).

%%--------------------------------------------------------------------
%% Internal Functions
%%--------------------------------------------------------------------

rep(<<"%c">>, ClientId, Topic) ->
    emqx_topic:feed_var(<<"%c">>, ClientId, Topic);
rep(<<"%u">>, undefined, Topic) ->
    Topic;
rep(<<"%u">>, Username, Topic) ->
    emqx_topic:feed_var(<<"%u">>, Username, Topic).

