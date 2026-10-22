defmodule MyBudgetWeb.SectionControllerTest do
  use MyBudgetWeb.ConnCase

  import MyBudget.MovementsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all section", %{conn: conn, scope: scope} do
      section = section_fixture(scope)
      conn = get(conn, ~p"/section")
      response = html_response(conn, 200)
      assert response =~ "Sessões"
      assert response =~ section.name
    end
  end

  describe "new section" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/section/new")
      assert html_response(conn, 200) =~ "Nova sessão"
    end
  end

  describe "create section" do
    test "redirects to index when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/section", section: @create_attrs)
      assert redirected_to(conn) == ~p"/section"

      conn = get(conn, ~p"/section")
      assert html_response(conn, 200) =~ "some name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/section", section: @invalid_attrs)
      response = html_response(conn, 200)
      assert response =~ "Nova sessão"
      assert response =~ "can&#39;t be blank"
    end
  end

  describe "show section" do
    setup [:create_section]

    test "displays section", %{conn: conn, section: section} do
      conn = get(conn, ~p"/section/#{section}")
      assert html_response(conn, 200) =~ "Sessão #{section.id}"
    end
  end

  describe "edit section" do
    setup [:create_section]

    test "renders form for editing chosen section", %{conn: conn, section: section} do
      conn = get(conn, ~p"/section/#{section}/edit")
      assert html_response(conn, 200) =~ "Editar sessão"
    end
  end

  describe "update section" do
    setup [:create_section]

    test "redirects to index when data is valid", %{conn: conn, section: section} do
      conn = put(conn, ~p"/section/#{section}", section: @update_attrs)
      assert redirected_to(conn) == ~p"/section"

      conn = get(conn, ~p"/section/#{section}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "redirects to show when return_to is show", %{conn: conn, section: section} do
      conn = put(conn, ~p"/section/#{section}", section: @update_attrs, return_to: "show")
      assert redirected_to(conn) == ~p"/section/#{section}"
    end

    test "renders errors when data is invalid", %{conn: conn, section: section} do
      conn = put(conn, ~p"/section/#{section}", section: @invalid_attrs)
      assert html_response(conn, 200) =~ "Editar sessão"
    end
  end

  describe "delete section" do
    setup [:create_section]

    test "deletes chosen section", %{conn: conn, section: section} do
      conn = delete(conn, ~p"/section/#{section}")
      assert redirected_to(conn) == ~p"/section"

      assert_error_sent 404, fn ->
        get(conn, ~p"/section/#{section}")
      end
    end
  end

  defp create_section(%{scope: scope}) do
    %{section: section_fixture(scope)}
  end
end
