defmodule TodoWeb.PageLive do
  use TodoWeb, :live_view

  alias Todo.Entries

  require Logger

  def mount(_params, _session, socket) do
    TodoWeb.Endpoint.subscribe("todo:entries")
    {:ok, stream(socket, :entries, Entries.list_entries())}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center w-full flex-col gap-2">
      <textarea
        class="text-center w-full h-12 border-2 border-slate rounded-xl drop-shadow-sm resize-none overflow-none"
        phx-blur="add"
        placeholder="What needs to be done?"
      ></textarea>
      <div class="flex flex-col gap-2" phx-update="stream" id="entries">
        <div
          :for={{id, entry} <- @streams.entries}
          id={id}
          class="flex border-2 border-slate-200 rounded-xl p-2 justify-center items-center gap-2"
        >
          <input type="checkbox" phx-click="done" phx-value-id={entry.id} checked={entry.done} />
          <div class={"grow #{if entry.done, do: "line-through", else: ""}"}>
            <%= entry.body %>
          </div>
          <button phx-click="delete" phx-value-id={entry.id} phx-throttle="2000">Delete</button>
        </div>
      </div>
    </div>
    """
  end

  # Handle local events
  def handle_event("add", %{"value" => ""}, socket) do
    Logger.debug("Ignoring empty entry")
    {:noreply, socket}
  end

  def handle_event("add", %{"value" => value}, socket) do
    entry = Entries.create_entry(%{body: value})
    TodoWeb.Endpoint.broadcast!("todo:entries", "add", {socket.id, entry})
    {:noreply, stream_insert(socket, :entries, entry, at: 0)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    entry = Entries.delete_entry_by!(id)
    TodoWeb.Endpoint.broadcast!("todo:entries", "delete", {socket.id, entry})
    {:noreply, stream_delete(socket, :entries, entry)}
  end

  def handle_event("done", %{"id" => id}, socket) do
    entry = Entries.update_entry_by!(id, %{done: true})
    TodoWeb.Endpoint.broadcast!("todo:entries", "done", {socket.id, entry})
    {:noreply, maybe_insert_to_end(socket, :entries, entry, entry.done)}
  end

  # Handle collaborative events
  def handle_info(%{topic: "todo:entries", payload: {socket_id, _}}, socket = %{id: socket_id}) do
    Logger.debug("Ignoring event from self")
    {:noreply, socket}
  end

  def handle_info(%{topic: "todo:entries", event: "delete", payload: {_, entry}}, socket) do
    {:noreply, stream_delete(socket, :entries, entry)}
  end

  def handle_info(%{topic: "todo:entries", event: "add", payload: {_, entry}}, socket) do
    {:noreply, stream_insert(socket, :entries, entry)}
  end

  def handle_info(%{topic: "todo:entries", event: "done", payload: {_, entry}}, socket) do
    {:noreply, maybe_insert_to_end(socket, :entries, entry, entry.done)}
  end

  defp maybe_insert_to_end(socket, name, item, true) do
    socket
    |> stream_delete(name, item)
    |> stream_insert(name, item, at: -1)
  end

  defp maybe_insert_to_end(socket, name, item, false) do
    stream_insert(socket, name, item)
  end
end
