defmodule TrainerWeb.Router do
  use TrainerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TrainerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TrainerWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/curriculum", CurriculumLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", TrainerWeb do
  #   pipe_through :api
  # end
end
