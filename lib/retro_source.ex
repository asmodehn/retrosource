defmodule RetroSource do

  @moduledoc """
    A Membrane plugin that acts as a source.
"""

# Ref: https://github.com/membraneframework/membrane_core/blob/master/lib/membrane/testing/source.ex
# TODO : get inspiration from https://github.com/membraneframework/membrane_generator_plugin
#  To generate blank video by default...

use Membrane.Source
alias Membrane.Buffer

def_options datastream: [
                spec: Ennumerable.t(),
                default: 0..9,
                description: """
                Enumerable | Stream to use as generator for data to output
                """
              ],
            stream_format: [
                spec: struct(),
                default: %Membrane.RemoteStream{},
                description: """
                StreamFormat to be sent before the `output`.
                """
              ]

def_output_pad :output, [accepted_format: Membrane.RemoteStream, mode: :pull]

@impl true
 def handle_init(_ctx, options) do

    continuation =
      &Enumerable.reduce(options.datastream, &1, fn
        x, {acc, 1} -> {:suspend, {[x | acc], 0}}
        x, {acc, counter} -> {:cont, {[x | acc], counter - 1}}
      end)

  {[],
    %{
      continuation: continuation,
      stream_format: options.stream_format
    }
  }
 end



  @impl true
  def handle_playing(_ctx, state) do
    # Because we need to send the stream fromat before sending any buffer to output
    {[stream_format: {:output, state.stream_format}], state}
  end

# @impl true
#  def handle_stopped_to_prepared(_ctx, state) do
#   raw_file_binary = File.read!(state.location)
#   content = String.split(raw_file_binary, "\n")
#   state = %{state | content: content}
#   { {:ok, [caps: {:output, %Packet{type: :custom_packets} }]}, state}
#  end
#
#  @impl true
#  def handle_prepared_to_stopped(_ctx, state) do
#   state = %{state | content: nil}
#   {:ok, state}
#  end


  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, state) when is_atom(state.continuation) do
    # nothing produced, ends the stream...
    {[end_of_stream: :output], state}
    # TODO: cf. gen_stage.streamer module for ideas...
  end

 def handle_demand(:output, size, :buffers, _ctx, state) do

  # IO.inspect(state)

  # TODO : handle ANY Stream...
  # First: data generator, inspired from stream stepper / streamer gen_stage, etc.
  # Ref: https://github.com/asmodehn/xest/pull/34/files#diff-c74b39473941db87d14a974d712390fcbe1a917736cc075c495411f1210e6d9d

  demand = size   # is this a good interpretation ???
  # Probably not : Ref : https://membrane.stream/guide/v0.7/demands.html#demand-unit

    case state.continuation.({:cont, {[], demand}}) do
      {:suspended, {list, 0}, continuation} ->

        state = %{state | continuation: continuation}

        action = [buffer: {:output, %Buffer{payload: :lists.reverse(list)} }]
        action = action ++ [end_of_stream: :output]

        {action, state}
      #   {:reply, :lists.reverse(list), continuation}

      {:done, {list, _}} ->
        action = [end_of_stream: :output]
        {action, state}

      {status, {list, _}} ->
        IO.inspect(status)

        state = %{state | continuation: status}

        # [first_packet | rest] = state.content
        # state = %{state | content: rest}


        action = [buffer: {:output, %Buffer{payload: :lists.reverse(list)} }]
        action = action ++ [redemand: :output]



        {action, state}
        # {:reply, :lists.reverse(list), status}

        smthg_else ->
          IO.inspect(smthg_else)
          # TODO : error : unplaned case ?
          { [end_of_stream: :output], %{}}
    end

  end



end
