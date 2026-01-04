defmodule MyBudgetWeb.Cldr do
  use Cldr,
    default_locale: "pt",
    locales: ["pt"],
    add_fallback_locales: false,
    gettext: MyApp.Gettext,
    data_dir: "./priv/cldr",
    otp_app: :my_budget,
    precompile_number_formats: ["R$ #.##0,##"],
    precompile_transliterations: [{:latn, :arab}, {:thai, :latn}],
    providers: [Cldr.Number],
    generate_docs: true,
    force_locale_download: false
end
