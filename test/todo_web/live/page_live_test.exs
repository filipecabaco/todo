defmodule TodoWeb.PageLiveTest do
  use TodoWeb.ConnCase
  alias Todo.Entries
  import Phoenix.LiveViewTest

  setup do
    entries = Enum.map(1..10, fn _ -> entry_fixture() end)
    %{entries: entries}
  end

  test "mounts view with entries", %{conn: conn, entries: entries} do
    conn = get(conn, "/live")

    {:ok, view, _html} = live(conn)

    Enum.each(entries, fn %{id: id, body: body} ->
      assert view |> element("#entries-#{id}") |> render() =~ body
    end)
  end

  test "blur creates new entry at the top of the list", %{conn: conn} do
    conn = get(conn, "/live")
    {:ok, view, _html} = live(conn)

    new_entry_content = random_string()

    view
    |> element("textarea")
    |> render_blur(%{"value" => new_entry_content})

    assert view
           |> element("#entries")
           |> render() =~ new_entry_content
  end

  test "delete entry removes element", %{conn: conn, entries: entries} do
    conn = get(conn, "/live")
    {:ok, view, _html} = live(conn)
    to_remove = Enum.random(entries)

    view
    |> element("#entries-#{to_remove.id}>button")
    |> render_click()

    refute has_element?(view, "#entries-#{to_remove.id}")
  end

  test "toggle entry sends to end of list and adds decoration", %{conn: conn, entries: entries} do
    conn = get(conn, "/live")
    {:ok, view, _html} = live(conn)

    [first_entry | _] = entries

    assert view
           |> element("#entries >:first-child")
           |> render() =~ "entries-#{first_entry.id}"

    view
    |> element("#entries-#{first_entry.id}>input[type=checkbox]")
    |> render_click()

    result =
      view
      |> element("#entries >:last-child")
      |> render()

    assert result =~ "entries-#{first_entry.id}"
    assert result =~ "line-through"
  end

  defp entry_fixture() do
    Entries.create_entry(%{body: random_string()})
  end

  defp random_string(), do: 10 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
end
