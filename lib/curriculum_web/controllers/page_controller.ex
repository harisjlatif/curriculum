defmodule CurriculumWeb.PageController do
  use CurriculumWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
