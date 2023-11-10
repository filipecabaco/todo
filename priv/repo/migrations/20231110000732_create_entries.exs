defmodule Todo.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :body, :string
      add :done, :boolean, default: false

      timestamps()
    end
  end
end
