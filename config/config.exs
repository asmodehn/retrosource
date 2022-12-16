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
          # stashing everything not staged, to test only what is in index
          {:cmd, "git stash push -u --keep-index"},

          # forceful formatting
          {:cmd, "mix format"},

          # CAREFUL: this will add all files that havent been stashed previously
          {:cmd, "git add -u"},

          # just once more to be sure
          {:cmd, "mix format --check-formatted"},

          # pop the stash to revert to current working tree
          {:cmd, "git stash pop"}
        ]
      ],
      pre_push: [
        verbose: false,
        tasks: [
          # stashing everything, to test only what is in HEAD
          {:cmd, "git stash push -u"},

          # run the command that must succeed, before pushing and bothering CI
          {:cmd, "mix dialyzer"},
          # {:cmd, "mix credo --strict"},
          {:cmd, "mix test --color"},

          # pop the stash to revert to current working tree
          {:cmd, "git stash pop"}
        ]
      ],
      post_checkout: [
        tasks: [
          {:cmd, "mix deps.get"}
        ]
      ]
    ]
end
