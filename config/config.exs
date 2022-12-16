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
          {:cmd, "mix format"},
          {:cmd, "git add -u"}
        ]
      ],
      pre_push: [
        verbose: false,
        tasks: [
          {:cmd, "mix dialyzer"},
          # {:cmd, "mix credo"},
          {:cmd, "mix test --color"},
          {:cmd, "echo 'Success!'"}
        ]
      ],
      post_checkout: [
        tasks: [
          {:cmd, "mix deps.get"}
        ]
      ]
    ]
end
