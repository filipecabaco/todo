# Small TODO Example application in Phoenix

Basic TODO application using LiveView that allows for concurrent usage.

## What was the setup?
After [installing Phoenix](https://hexdocs.pm/phoenix/installation.html) simply ran `mix phx.new todo --no-gettext`

## How to run it?

* Startup the docker container with `docker compose up -d`
* `mix setup` to get your environment ready
* `mix phx.server` to run your server on port 4000

## What's happening?

You will find a Todo list where if you type and leave the typing area it will add automatically a new entry to your todo list. You can also do this in a concurrent manner where you can have multiple people (tabs) add, removing, toggling entries and those changes will be reflected in every users screen.

This is achieved thanks to multiple elements from the Phoenix Framework:
* LiveView to render newly changed information in a reactive way
* Phoenix.PubSub which is a way to distribute events across subscribers
* Ecto for database connection

## Nitty Gritty

### Database usage

Ecto connects to your DB and manages that connection while also offering connection guarantees (e.g. for fun try to kill your docker container while running the server and then bring it back up)

To actually have an element that represents our todo entry you will need
* A migration
  * Created with `mix ecto.gen.migration create_entries`
  * In `priv/repo/migrations/20231110000732_create_entries.exs` create the table using the `Ecto.Migration` functions
* Create a schema
  * Created a file `lib/todo/entries/entry.ex`
  * Use `Ecto.Schema` to define what are the fields from this new entity
  * Define a function called `changeset` that will tell what is required to add / update a new entity using the functions from `Ecto.Changeset`. This changeset is responsible for the validation of the changes we want to implement on a entry entity.
* Call the database
  * Created `lib/todo/entries.ex`
  * `Repo.all` runs a query to fetch sorted data using the `Ecto.Query` DSL
  * `Repo.update` and `Repo.insert` use a changeset so they can check if it's valid before going to the database
  * `Repo.delete` deletes based on a given entry

### Create view

Defined at `lib/todo_web/live/page_live.ex`
#### Start up the view

The `mount` function will take care of that and here we define a couple of important things:

First we subscrine to important events:
```elixir
TodoWeb.Endpoint.subscribe("todo:entries")
```

Here we will see that we're using a stream and we're loading our entries into it:
```elixir
stream(socket, :entries, Entries.list_entries())
```
This means that the server won't store this information on his side, making it possible to insert as many entries we want withouth impacting the server, only the client.

#### Draw the view

`render` will define the HTML to be used by your view.

Two things are important to notice:

Elements have `phx-*` attributes that are actually special to Phoenix and they will trigger / handle things differently. Check more about them in [Bindings](hexdocs.pm/phoenix_live_view/bindings.html)

The other thing is that we have a for cycle creating multiple elements based on what the stream contains

```elixir
 <div :for={{id, entry} <- @streams.entries} id={id} class="flex border-2 border-slate-200 rounded-xl p-2 justify-center items-center gap-2" >
  <input type="checkbox" phx-click="done" phx-value-id={entry.id} checked={entry.done} />
  <div class={"grow #{if entry.done, do: "line-through", else: ""}"}>
    <%= entry.body %>
  </div>
  <button phx-click="delete" phx-value-id={entry.id} phx-throttle="2000">Delete</button>
</div>
```

#### React to local changes

There's a section where we have all event handlers by pattern matching against received events. Check all the `handle_event` functions.
In each of this functions we are handling the action of a given event, we emit an event to all connected clients and then telling how the stream should be updated.

#### React to external changes

The same way we have a way to handle local change we have a way to handle external change based on the PubSub events. Those are handled by `handle_info` and there's one extra function to avoid acting on our own events.

In theory here we could actually update our own view at this point but wanted to keep those separate to make more sense to new users.

### Route the user

Done at `lib/todo_web/router.ex` where we tell it that we will have a `live` view:
```elixir
 scope "/", TodoWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/live", PageLive # This one
  end
```

### Test it out

LiveView includes a great toolsuite of testing so in `test/todo_web/live/page_live_test.exs` you will find all the code used for testing. They will be closer to a e2e test situation that keeps updating our view with every action we take.

To run them you just need to do `mix test`

## Conclusion

Have fun with this project, try to extend it by:
* Adding a live cursor which would require [LiveView hooks and JS interop](https://hexdocs.pm/phoenix_live_view/js-interop.html)
* Adding more rich editting with [delta-elixir](https://github.com/slab/delta-elixir)
* Change your persistency layer to ETS using [etso](https://github.com/evadne/etso) so it's all in memory only
* Adding Machine Learning with [Bumblebee](https://github.com/elixir-nx/bumblebee) to categorize each issue

