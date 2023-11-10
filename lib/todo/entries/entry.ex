defmodule Todo.Entries.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entries" do
    field :body, :string
    field :done, :boolean, default: false

    timestamps()
  end

  def changeset(entry, params \\ %{}) do
    entry
    |> cast(params, [:body, :done])
    |> validate_required([:body])
  end
end
