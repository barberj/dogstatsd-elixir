defmodule DogStatsd do
  use GenServer
  use DogStatsd.DogStatsd

  @default_host "127.0.0.1"
  @default_port 8125

  def new do
    start_link(%{})
  end

  def new(host, port, opts \\ %{}) do
    config = opts
             |> Map.put_new(:host, host)
             |> Map.put_new(:port, port)
    start_link(config)
  end

  def start_link(config, options \\ []) do
    config = config
             |> Map.take([:host, :port, :namespace, :tags, :max_buffer_size])
             |> Map.put_new(:max_buffer_size, 50)
             |> Map.put_new(:buffer, [])


    GenServer.start_link(__MODULE__, config, options)
  end

  def max_buffer_size(dogstatsd) do
    GenServer.call(dogstatsd, :max_buffer_size)
  end

  def namespace(dogstatsd) do
    GenServer.call(dogstatsd, :get_namespace)
  end

  def namespace(dogstatsd, namespace) do
    GenServer.call(dogstatsd, {:set_namespace, namespace})
  end

  def host(dogstatsd) do
    GenServer.call(dogstatsd, :get_host) || System.get_env("DD_AGENT_ADDR") || @default_host
  end

  def host(dogstatsd, host) do
    GenServer.call(dogstatsd, {:set_host, host})
  end

  def port(dogstatsd) do
    GenServer.call(dogstatsd, :get_port) || System.get_env("DD_AGENT_PORT") || @default_port
  end

  def port(dogstatsd, port) do
    GenServer.call(dogstatsd, {:set_host, port})
  end

  def tags(dogstatsd) do
    GenServer.call(dogstatsd, :get_tags) || []
  end

  def tags(dogstatsd, tags) do
    GenServer.call(dogstatsd, {:set_tags, tags})
  end

  def socket(dogstatsd) do
    GenServer.call(dogstatsd, :get_socket)
  end

  def prefix(dogstatsd) do
    GenServer.call(dogstatsd, :get_prefix)
  end

  def add_to_buffer(dogstatsd, message) do
    GenServer.call(dogstatsd, {:add_to_buffer, message})
  end

  def get_buffer(dogstatsd) do
    GenServer.call(dogstatsd, :get_buffer)
  end

  def flush_buffer(dogstatsd) do
    send_to_socket dogstatsd, dogstatsd |> get_buffer |> Enum.join("\n")
    GenServer.call(dogstatsd, :flush_buffer)
  end


  ###################
  # Server Callbacks

  def init(config) do
    {:ok, config}
  end

  def handle_call(:max_buffer_size, _from, config) do
    {:reply, config[:max_buffer_size], config}
  end

  def handle_call(:get_namespace, _from, config) do
    {:reply, config[:namespace], config}
  end

  def handle_call({:set_namespace, nil}, _from, config) do
    config = config
             |> Map.put(:namespace, nil)
             |> Map.put(:prefix, nil)

    {:reply, config[:namespace], config}
  end

  def handle_call({:set_namespace, namespace}, _from, config) do
    config = config
             |> Map.put(:namespace, namespace)
             |> Map.put(:prefix, "#{namespace}.")

    {:reply, config[:namespace], config}
  end

  def handle_call(:get_prefix, _from, config) do
    {:reply, config[:prefix], config}
  end

  def handle_call(:get_host, _from, config) do
    {:reply, config[:host], config}
  end

  def handle_call({:set_host, host}, _from, config) do
    config = config
             |> Map.put(:host, host)

    {:reply, config[:host], config}
  end

  def handle_call(:get_port, _from, config) do
    {:reply, config[:port], config}
  end

  def handle_call({:set_port, port}, _from, config) do
    config = config
             |> Map.put(:port, port)

    {:reply, config[:port], config}
  end

  def handle_call(:get_tags, _from, config) do
    {:reply, config[:tags], config}
  end

  def handle_call({:set_tags, tags}, _from, config) do
    config = config
             |> Map.put(:tags, tags)

    {:reply, config[:tags], config}
  end

  def handle_call({:add_to_buffer, message}, _from, config) do
    config = update_in(config, [:buffer], &(&1 ++ [message]))

    {:reply, config[:buffer], config}
  end

  def handle_call(:flush_buffer, _from, config) do
    {:reply, [], Map.put(config, :buffer, [])}
  end

  def handle_call(:get_buffer, _from, config) do
    {:reply, config[:buffer], config}
  end

end