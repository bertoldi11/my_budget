defmodule MyBudgetWeb.Router do
  use MyBudgetWeb, :router

  import MyBudgetWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyBudgetWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyBudgetWeb do
    pipe_through :browser

    live_session :home_session,
      on_mount: [{MyBudgetWeb.UserAuth, :require_authenticated}] do
      live "/", HomeLive.Index, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MyBudgetWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:my_budget, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MyBudgetWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MyBudgetWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MyBudgetWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", MyBudgetWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{MyBudgetWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Movement 

  scope "/", MyBudgetWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_app,
      on_mount: [{MyBudgetWeb.UserAuth, :require_authenticated}] do
      # Category
      live "/category", CategoryLive.Index, :index
      live "/category/new", CategoryLive.Form, :new
      live "/category/:id", CategoryLive.Show, :show
      live "/category/:id/edit", CategoryLive.Form, :edit

      # Payment Method
      live "/payment_method", PaymentMethodLive.Index, :index
      live "/payment_method/new", PaymentMethodLive.Form, :new
      live "/payment_method/:id", PaymentMethodLive.Show, :show
      live "/payment_method/:id/edit", PaymentMethodLive.Form, :edit

      # Section 
      live "/section", SectionLive.Index, :index
      live "/section/new", SectionLive.Form, :new
      live "/section/:id", SectionLive.Show, :show
      live "/section/:id/edit", SectionLive.Form, :edit

      # Movement
      live "/movement", MovementLive.Index, :index
      live "/movement/new", MovementLive.Form, :new
      live "/movement/:id", MovementLive.Show, :show
      live "/movement/:id/edit", MovementLive.Form, :edit
    end
  end
end
