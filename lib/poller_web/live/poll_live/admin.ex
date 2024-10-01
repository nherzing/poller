defmodule PollerWeb.PollLive.Admin do
  use PollerWeb, :live_view

  alias Poller.Polls.Poll

  @choices [
    %{id: "1", label: "<1ms"},
    %{id: "2", label: "<10ms"},
    %{id: "3", label: "<100ms"},
    %{id: "4", label: "<1s"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Poll.register_admin()
      poll = Poll.reset(@choices)

      {:ok, assign(socket, :poll, poll)}

      {:ok, assign(socket, :poll, poll)}
    else
      {:ok, assign(socket, :poll, nil)}
    end
  end

  @impl true
  def handle_info(poll, socket) do
    {:noreply, assign(socket, :poll, poll)}
  end

  @impl true
  def handle_event("reset", _, socket) do
    poll = Poll.reset(@choices)
    {:noreply, assign(socket, :poll, poll)}
  end

  @impl true
  def handle_event("show-results", _, socket) do
    state = Poll.show_results()
    {:noreply, assign(socket, state)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@poll}>
      <%= inspect(@poll) %>
      <h1>Admin poll</h1>
      <button
        phx-click="reset"
        type="button"
        class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
      >
        Reset
      </button>
      <button
        :if={@poll.state == :voting}
        phx-click="show-results"
        type="button"
        class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
      >
        Show Results
      </button>
      <p>User Count: <%= MapSet.size(@poll[:users]) %></p>
      <p>Vote Count: <%= map_size(@poll[:votes]) %></p>
      <p>Choices:</p>
      <ul>
        <li :for={choice <- @poll[:choices]}>
          <%= choice.id %> : <%= choice.label %> : <%= vote_count(@poll, choice.id) %>
        </li>
      </ul>
    </div>
    """
  end

  defp vote_count(poll, id) do
    poll.votes |> Map.filter(fn {_, vid} -> id == vid end) |> map_size()
  end
end
