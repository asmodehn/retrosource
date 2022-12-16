import Config

if Mix.env() == :dev do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    # branches: [
    #   whitelist: ["feature-.*"],
    #   blacklist: ["master"]
    # ],
    hooks: [
      pre_commit: [
        tasks: [
          # forceful formatting, careful: may create conflict with stash
          {:cmd, "mix format"},
          # file are now formatted, but not added to commit just yet !

          # run the command that must succeed, before committing and bothering CI
          {:cmd, "mix dialyzer"},
          {:cmd, "mix test --trace --color"}
        ]
      ],
      post_checkout: [
        tasks: [
          {:cmd, "mix deps.get"},
          {:cmd, "mix credo --strict"}
        ]
      ]
    ]
end
