defmodule MyspacePubsubTest do
  @moduledoc """
  Test the MyspaceIPFS API

  This test suite is designed to test the MyspaceIPFS API. It is not designed to test the IPFS API
  itself. It is designed to test the MyspaceIPFS API wrapper. This test suite is designed to be run

  NB! The tests are not mocked. They are designed to be run against a live IPFS node. This is
  """
  use ExUnit.Case, async: true

  import MyspacePubsub
  @topic Nanoid.generate()

  test "subscribe to a topic" do
    {:ok, pid} = sub(@topic, self())
    assert is_pid(pid)
    assert Process.alive?(pid)

    # ls
    sub(@topic, self())
    {:ok, topics} = ls()
    assert is_list(topics)
    assert Enum.member?(topics, @topic)

    topics = ls!()
    assert is_list(topics)
    assert Enum.member?(topics, @topic)

    # Publish and receive a message
    sub(@topic, self())
    assert_receive {:raw_pubsub_message, _}
    # pub("hello", @topic)
    # assert_receive {:myspace_pubsub_message, "hello"}

    # Get peers. Probably an empty file.
    {:ok, peerslist} = peers(@topic)
    assert is_list(peerslist) || is_nil(peerslist)
  end
end
