defmodule RetroSource.PipelineTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Bunch

  import Membrane.Testing.Assertions

  alias Membrane.Buffer
  alias Membrane.Testing

  import Membrane.ChildrenSpec

  test "forward input to two outputs" do
    range = 1..100

    # Simple pipeline setup in test
    pipeline_struct = [
      child(:src, %RetroSource{datastream: range})
      |> child(:sink, %Testing.Sink{})
    ]

    assert {:ok, _supervisor_pid, pid} = Testing.Pipeline.start_link(structure: pipeline_struct)

    # Assert correct actions taken (helps cleanup error trace in tests)
    # Note these may be asserted out of order, as per BEAM select receive for messages

    assert_pipeline_setup(pid)
    assert_pipeline_play(pid)
    assert_sink_stream_format(pid, :sink, %Membrane.RemoteStream{})
    assert_start_of_stream(pid, :sink, :input)
    assert_pipeline_notified(pid, :sink, {:start_of_stream, :input})

    assert_end_of_stream(pid, :sink, :input)

    # assert every message was received
    # Enum.each(range, fn element ->
    #   assert_sink_buffer(pid, :sink, %Buffer{payload: ^element})
    # end)

    Testing.Pipeline.terminate(pid, blocking?: true)
  end
end
