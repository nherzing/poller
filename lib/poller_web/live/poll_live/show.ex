defmodule PollerWeb.PollLive.Show do
  use PollerWeb, :live_view

  alias Poller.Polls.Poll

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, state} = Poll.register()
      {:ok, socket |> assign(state) |> assign(vote: nil, results: nil)}
    else
      {:ok, assign(socket, poll: nil, vote: nil, results: nil)}
    end
  end

  @impl true
  def handle_event("vote", %{"id" => id}, socket) do
    Poll.vote(id)
    {:noreply, assign(socket, :vote, id)}
  end

  @impl true
  def handle_info({:update, state}, socket) do
    {:noreply, assign(socket, state)}
  end

  @impl true
  def handle_info(:reset, socket) do
    {:ok, poll} = Poll.register()
    {:noreply, assign(socket, poll: poll, vote: nil, results: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@results} class="flex flex-col p-4 space-y-4">
      <div :for={choice <- @poll.choices} class="flex-grow">
        <div class={[
          "w-full h-full text-2xl font-bold py-8 rounded-lg shadow-lg transition duration-300 ease-in-out transform",
          if(@vote == choice.id,
            do: "bg-green-500 hover:bg-green-600 text-white",
            else: "bg-blue-500 hover:bg-blue-600 text-white"
          )
        ]}>
          <div
            class="absolute left-0 top-0 h-full rounded-lg bg-indigo-600"
            style={"width: #{(Map.get(@results, choice.id, 0)/(@results |> Map.values |> Enum.sum()))*100}%"}
          >
          </div>
          <div class="absolute left-0 right-0 top-0 bottom-0">
            <div class="flex justify-center items-center">
              <%= choice.label %> : <%= Map.get(@results, choice.id, 0) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div :if={@poll && !@results} class="flex flex-col p-4 space-y-4">
      <div :for={choice <- @poll.choices} class="flex-grow">
        <button
          phx-click="vote"
          phx-value-id={choice.id}
          class={[
            "w-full h-full text-2xl font-bold py-8 rounded-lg shadow-lg transition duration-300 ease-in-out transform hover:scale-105",
            if(@vote == choice.id,
              do: "bg-green-500 hover:bg-green-600 text-white",
              else: "bg-blue-500 hover:bg-blue-600 text-white"
            )
          ]}
        >
          <%= choice.label %>
        </button>
      </div>
    </div>
    """
  end
end
