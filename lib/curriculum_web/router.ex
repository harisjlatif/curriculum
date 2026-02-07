defmodule CurriculumWeb.Router do
  use CurriculumWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CurriculumWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CurriculumWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/curriculum", CurriculumLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", CurriculumWeb do
  #   pipe_through :api
  # end
end
