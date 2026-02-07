defmodule TrainerWeb.PageController do
  use TrainerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
