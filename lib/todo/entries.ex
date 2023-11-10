defmodule Todo.Entries do
  alias Todo.Entries.Entry
  alias Todo.Repo
  import Ecto.Query

  def list_entries, do: Repo.all(from e in Entry, order_by: [asc: e.done, asc: e.inserted_at])

  def get_entry!(id) when is_binary(id), do: id |> String.to_integer() |> get_entry!()
  def get_entry!(id), do: Repo.get!(Entry, id)

  def create_entry(attrs \\ %{}) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert!()
  end

  def update_entry_by!(id, attrs \\ %{}) do
    id
    |> get_entry!()
    |> Entry.changeset(attrs)
    |> Repo.update!()
  end

  def delete_entry_by!(id), do: id |> get_entry!() |> Repo.delete!()
end
