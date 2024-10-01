defmodule Poller.Polls.Poll do
  use GenServer

  @pubsub Poller.PubSub

  # Client

  def start_link(choices) do
    GenServer.start_link(
      __MODULE__,
      %{choices: choices, users: MapSet.new(), votes: %{}, state: :voting},
      name: :poller
    )
  end

  def register_admin() do
    :ok = Phoenix.PubSub.subscribe(@pubsub, "poll:admin")
  end

  def admin_state() do
    GenServer.call(:poller, :admin_state)
  end

  def state() do
    GenServer.call(:poller, :state)
  end

  def register() do
    GenServer.call(:poller, {:register, self()})
    Phoenix.PubSub.subscribe(@pubsub, "poll:user")
    {:ok, state()}
  end

  def unregister() do
    Phoenix.PubSub.unsubscribe(@pubsub, "poll:user")
    GenServer.call(:poller, :unregister)
  end

  def vote(id) do
    GenServer.cast(:poller, {:vote, self(), id})
  end

  def show_results() do
    GenServer.call(:poller, :show_results)
  end

  def reset(choices) do
    GenServer.call(:poller, {:reset, choices})
    admin_state()
  end

  def vote_counts(poll) do
    Enum.reduce(poll[:votes], %{}, fn {_, id}, acc ->
      Map.update(acc, id, 1, &(&1 + 1))
    end)
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:admin_state, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:state, _, state) do
    if state.state == :results do
      {:reply, %{poll: state, results: vote_counts(state)}, state}
    else
      {:reply, %{poll: Map.take(state, [:choices])}, state}
    end
  end

  @impl true
  def handle_call({:register, pid}, _, state) do
    state = %{state | users: MapSet.put(state[:users], pid)}
    Process.monitor(pid)
    :ok = Phoenix.PubSub.broadcast(@pubsub, "poll:admin", state)
    {:reply, nil, state}
  end

  @impl true
  def handle_call({:reset, choices}, _, _state) do
    state = %{choices: choices, users: MapSet.new(), votes: %{}, state: :voting}
    :ok = Phoenix.PubSub.broadcast(@pubsub, "poll:user", :reset)
    {:reply, nil, state}
  end

  @impl true
  def handle_call(:show_results, _, state) do
    Phoenix.PubSub.broadcast!(
      @pubsub,
      "poll:user",
      {:update, %{poll: state, results: vote_counts(state)}}
    )

    {:reply, %{state | state: :results}, %{state | state: :results}}
  end

  @impl true
  def handle_cast({:vote, pid, id}, state) do
    state = %{state | votes: Map.put(state[:votes], pid, id)}
    :ok = Phoenix.PubSub.broadcast(@pubsub, "poll:admin", state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = %{
      state
      | users: MapSet.delete(state[:users], pid),
        votes: Map.delete(state[:votes], pid)
    }

    :ok = Phoenix.PubSub.broadcast(@pubsub, "poll:admin", state)

    {:noreply, state}
  end
end
