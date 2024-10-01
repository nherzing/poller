defmodule Poller.PollsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Poller.Polls` context.
  """

  @doc """
  Generate a poll.
  """
  def poll_fixture(attrs \\ %{}) do
    {:ok, poll} =
      attrs
      |> Enum.into(%{

      })
      |> Poller.Polls.create_poll()

    poll
  end
end
