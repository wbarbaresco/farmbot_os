defmodule Farmbot.BotState.Network do
  @moduledoc """
    I DONT KNOW WHAT IM DOING
  """

  defmodule State do
    @moduledoc false

    defstruct [
      connected?: false,
      connection: nil
    ]

    @type t :: %__MODULE__{
      connected?: boolean,
      connection: :ethernet | {String.t, String.t}
    }

    @spec broadcast(t) :: t
    def broadcast(%State{} = state) do
      GenServer.cast(BotState.Monitor, state)
      state
    end
  end

  use GenServer
  require Logger
  alias Farmbot.BotState

  def init(_args) do
    NetMan.put_pid(__MODULE__)

    s = __MODULE__
        |> SafeStorage.read
        |> load
        |> start_connection
        |> State.broadcast
    {:ok, s}
  end

  @spec load({:ok, State.t}) :: State.t
  defp load({:ok, %State{} = state}) do
    state
  end

  @spec load(any) :: State.t
  defp load(_), do: %State{}

  @spec start_connection(State.t) :: State.t
  defp start_connection(%State{} = state) do
    NetMan.connect(state.connection, __MODULE__)
    state
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.warn ">> got an unhandled call in \
                 Network State tracker: #{inspect event}"
    dispatch :unhandled, state
  end

  # for development mode
  def handle_cast({:connected, :dev, ip_address}, %State{} = state) do
    GenServer.cast(BotState.Configuration,
                  {:update_info, :private_ip, ip_address})
    GenServer.cast(BotState.Authorization, :try_log_in)
    new_state = %State{state | connected?: true, connection: :dev}
    save new_state
    dispatch new_state
  end

  def handle_cast({:connected, connection, ip_address}, %State{} = state) do
    Process.sleep(2000) # I DONT KNOW WHY THIS HAS TO BE HERE
    BotState.set_time
    GenServer.cast(BotState.Configuration,
                  {:update_info, :private_ip, ip_address})
    GenServer.cast(BotState.Authorization, :try_log_in)
    new_state = %State{state | connected?: true, connection: connection}
    save new_state
    dispatch new_state
  end

  def handle_cast(event, %State{} = state) do
    Logger.warn ">> got an unhandled cast in\
                Network State tracker: #{inspect event}"
    dispatch state
  end

  defp dispatch(reply, %State{} = state) do
    State.broadcast(state)
    {:reply, reply, state}
  end

  defp dispatch(%State{} = state) do
    State.broadcast(state)
    {:noreply, state}
  end

  @spec save(State.t) :: :ok | {:error, atom}
  defp save(%State{} = state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end
end
