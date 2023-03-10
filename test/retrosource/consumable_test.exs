defmodule RetroSource.Consumable.Test do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Membrane.Buffer
  alias RetroSource.CommonTest

  describe "RetroSource.Consumable with Enumerable" do
    setup do
      sourcemap = %RetroSource.Consumable{
        datastream: 1..100
      }

      %{sourcemap: sourcemap}
    end

    test "init stores the continuation in state", %{sourcemap: sourcemap} do
      {[],
       %{
         continuation: continuation,
         stream_format: stream_format
       }} = RetroSource.Consumable.handle_init(nil, sourcemap)

      assert stream_format == %Membrane.RemoteStream{}

      # TODO : assert continuation behavior ??? HOW ???
    end

    test "play send the stream format", %{sourcemap: sourcemap} do
      {[], state} = RetroSource.Consumable.handle_init(nil, sourcemap)

      {actions, state} = RetroSource.Consumable.handle_playing(nil, state)
      assert actions == [stream_format: {:output, state.stream_format}]
    end

@tag skip: true
    test "stream out data on demand, N at a time", %{sourcemap: sourcemap} do
      {[],
       %{
         continuation: continuation,
         stream_format: _stream_format
       }} = RetroSource.Consumable.handle_init(nil, sourcemap)

      # looping with increasing buffersize in demand
      for n <- 1..100 do
        {actions, _state} =
          RetroSource.Consumable.handle_demand(:output, n, :buffers, nil, %{
            continuation: continuation
          })

        # asserting we only buffer the demanded size in output
        assert buffer: {:output, %Buffer{payload: Enum.to_list(1..n)}} in actions

        # asserting we follow up with the rest of the stream if possible, or properly end otherwise
        assert {:end_of_stream, :output} in actions
      end
    end

    @tag skip: true
    test "handles too large demand properly", %{sourcemap: sourcemap} do
      {[],
       %{
         continuation: continuation,
         stream_format: _stream_format
       }} = RetroSource.Consumable.handle_init(nil, sourcemap)

      # bigger demand than possible -> redemand (???)
      {actions, _state} =
        RetroSource.Consumable.handle_demand(:output, 101, :buffers, nil, %{
          continuation: continuation
        })

      # asserting we only buffer the demanded size in output
      assert buffer: {:output, %Buffer{payload: Enum.to_list(1..100)}} in actions

      # asserting we follow up with the rest of the stream if possible, or properly end otherwise
      # assert {:redemand, :output} in actions
      assert {:end_of_stream, :output} in actions
    end
  end

  describe "RetroSource.Consumable with infinite Stream" do
    setup do
      sourcemap = %RetroSource.Consumable{
        datastream:
          Stream.unfold(0, fn
            n -> {n, n + 1}
          end)
      }

      %{sourcemap: sourcemap}
    end

@tag skip: true
    test "init stores the continuation in state", %{sourcemap: sourcemap} do
      {[],
       %{
         continuation: continuation,
         stream_format: stream_format
       }} = RetroSource.Consumable.handle_init(nil, sourcemap)

      assert stream_format == %Membrane.RemoteStream{}

      # TODO : assert continuation behavior ??? HOW ???
    end

    test "play send the stream format", %{sourcemap: sourcemap} do
      {[], state} = RetroSource.Consumable.handle_init(nil, sourcemap)

      {actions, state} = RetroSource.Consumable.handle_playing(nil, state)
      assert actions == [stream_format: {:output, state.stream_format}]
    end

@tag skip: true
    test "stream out data on demand, N at a time", %{sourcemap: sourcemap} do
      {[],
       %{
         continuation: continuation,
         stream_format: _stream_format
       }} = RetroSource.Consumable.handle_init(nil, sourcemap)

      # looping with increasing buffersize in demand
      for n <- 0..100 do
        {actions, _state} =
          RetroSource.Consumable.handle_demand(:output, n, :buffers, nil, %{
            continuation: continuation
          })

        # asserting we buffer all the demand in output
        for m <- 0..n do
          assert %Buffer{payload: m} in actions.buffer.output
        end

        for m <- n..100 do
          refute %Buffer{payload: m} in actions.buffer.output
        end

        # asserting we follow up with the rest of the stream if possible, or properly end otherwise
        assert {:end_of_stream, :output} in actions
      end
    end

    @tag skip: true
    test "handles too large demand properly", %{sourcemap: sourcemap} do
      {[],
       %{
         continuation: continuation,
         stream_format: _stream_format
       }} = RetroSource.Consumable.handle_init(nil, sourcemap)

      # bigger demand than possible -> redemand (???)
      {actions, _state} =
        RetroSource.Consumable.handle_demand(:output, 101, :buffers, nil, %{
          continuation: continuation
        })

      # asserting we only buffer the demanded size in output
      assert {:buffer, {:output, %Buffer{payload: Enum.to_list(1..100)}}} in actions

      # asserting we follow up with the rest of the stream if possible, or properly end otherwise
      # assert {:redemand, :output} in actions
      assert {:end_of_stream, :output} in actions
    end
  end
end
