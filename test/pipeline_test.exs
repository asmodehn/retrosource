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
        child(:src, %Testing.Source{output: range})
        |> child(:sink, %Testing.Sink{})
      ]

    assert {:ok, _supervisor_pid, pid} = Testing.Pipeline.start_link([
      structure: pipeline_struct
    ])

    # Wait for EndOfStream message on the sink
    assert_end_of_stream(pid, :sink, :input, 3000)

    # assert every message was received
    Enum.each(range, fn element ->
      assert_sink_buffer(pid, :sink, %Buffer{payload: ^element})
    end)

    Testing.Pipeline.terminate(pid, blocking?: true)
  end
end