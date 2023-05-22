# ==========>  README  <==========
#
# This file has been generated by:
# 
#   nix flake init --template github:zeme-iohk/iogx
#
# You should do the following:
# 
#   0. Read through this entire file once
#   1. Change the flake `description` field (line 17)
#   2. Override or add new flake inputs (line 35)
#   3. Modify the `flakeopts` value (line 40)
#   4. Run `nix develop` and read the available commands
#   5. Run `cabal test all` to ensure that everything is working
#   6. Delete this comment

{
  description = "";

  inputs = {

    # The following inputs are managed by iogx:
    # 
    #   CHaP, flake-utils, haskell.nix, nixpkgs, hackage, 
    #   iohk-nix, sphinxcontrib-haddock, pre-commit-hooks-nix, 
    #   haskell-language-server, nosys, std, bitte-cells, tullia.
    # 
    # They will be available in both systemized and desystemized flavours. 
    # Do not re-add those inputs again here. 
    # If you need to, you can override them like this instead:
    # 
    #   iogx.inputs.hackage.url = "github:input-output-hk/hackage/my-branch" 
    iogx.url = "github:zeme-iohk/iogx";

    # Other inputs can be defined as usual.
    # foobar.url = "github:foo/bar";
  };

  outputs = inputs:
    let
      flakeopts = {

        # Boilerplate: simply pass your unmodified inputs here.
        inherit inputs;

        # Trace debugging information in the `mkFlake` function.
        # This field is optional.
        # This field defaults to true.
        debug = true;

        # While migrating to IOGX, you might want to keep the old flake outputs 
        # alongside the new ones. An easy way to do this is to prefix (nest) 
        # each output group { packages, apps, devShells, <nonstandard>, ... } 
        # with a custom name. 
        # For example, if `flakeOutputsPrefix = "__foo__"` then the flake will 
        # have outputs like these:
        # `outputs.devShells.x86_64-darwin.__foo__.baz`
        # `outputs.nonstandard.x86_64-linux.__foo__.bar`
        # This field is optional.
        # This field defaults to "", which means: do not nest.
        flakeOutputsPrefix = "";

        # The root of the repository.
        # The path *must* contain the `cabal.project` file. 
        # This field is required.
        repoRoot = ./.;

        # The list of supported systems.
        # This field is optional, but it cannot be the empty list.
        # This field defaults to [ "x86_64-linux" "x86_64-darwin" ]
        systems = [ "x86_64-linux" "x86_64-darwin" ];

        # The list of supported GHC versions.
        # This field is optional, but it cannot be the empty list.
        # This field defaults to [ "ghc8107" ]
        # Available compilers are: 
        #   ghc8107 ghc925
        haskellCompilers = [ "ghc8107" ];

        # The default GHC compiler.
        # When running `nix develop` this is the compiler that will be available 
        # in the shell. 
        # This field is optional, but it must be one of `haskellCompilers`.
        # This field defaults to the first compiler in `haskellCompilers`.
        defaultHaskellCompiler = "ghc8107";

        # The host system for cross-compiling on migwW64.
        # Do not set this value if your project does not support 
        # cross-compilation, otherwise set this value to the host system, 
        # usually `x86_64-linux`.
        # This field is optional.
        # This field defaults to "", which means: do not cross-compile.
        haskellCrossSystem = "";

        # A function evaluating to a haskell.nix project.
        # For documentation see the stub file ./nix/haskell-project.nix 
        # generated by the template.
        # This field is optional.
        # This field defaults to `import ./nix/haskell-project.nix`
        haskellProjectFile = import ./nix/haskell-project.nix;

        # A function evaluating to system-dependent flake outputs.
        # For documentation see the stub file ./nix/per-system-outputs.nix 
        # generated by the template.
        # If you want custom outputs, you should set this value to 
        # `import ./nix/per-system-outputs.nix`
        # This field is optional.
        # This field defaults to a noop, which means: no custom outputs.
        perSystemOutputs = _: { };

        # Only for cosmetic purposes, the shell name will be included in the 
        # default `shellPrompt` and appear in the shell welcome message. 
        # You should use your project name.
        # This field is optional.
        # This field defaults to "iogx";
        shellName = "iogx";

        # Only for cosmetic purposes, the shell welcome message will be printed 
        # when you enter the shell.
        # This field is optional.
        # This field defaults to "Welcome to $shellName!";
        shellWelcomeMessage = "🤟 \\033[1;31mWelcome to ${shellName}\\033[0m 🤟";

        # Shell prompt i.e. the value of the `PS1` evnvar. 
        # This field is optional.
        # This field defaults to the familiar nix-shell green prompt.
        # NOTE: because this is a nix string that will be embedded as a bash 
        # string, you need to double-escape the left slashes:
        # Example: 
        #   bash = "\n\[\033[1;32m\][nix-shell:\w]\$\[\033[0m\] "
        #   shellPrompt = "\n\\[\\033[1;32m\\][nix-shell:\\w]\\$\\[\\033[0m\\] ";
        shellPrompt = "\n\\[\\033[1;32m\\][${shellName}:\\w]\\$\\[\\033[0m\\] ";

        # A function evaluating to your devShell module.
        # For documentation see the stub file ./nix/shell-module.nix 
        # generated by the template.
        # If you want a custom shell, you should set this value to 
        # `import ./nix/shell-module.nix`
        # This field is optional.
        # This field defaults to a noop, which means: no custom shell.
        shellModule = _: { };

        # Whether to populate `hydraJobs` with the haskell artifacts.
        # In general you want to set this to true.
        # If this field is set to false, then the following fields have no
        # effect: 
        #   excludeProfiledHaskellFromHydraJobs
        #   blacklistedHydraJobs
        #   enableHydraPreCommitCheck
        # This field is optional.
        # This field default to true.
        includeHydraJobs = true;

        # Whether to exclude profiled haskell builds from CI.
        # In general you don't want to run profiled builds in CI.
        # This field is optional.
        # This field default to true.
        excludeProfiledHaskellFromHydraJobs = true;

        # A list of derivations to be excluded from CI.
        # Each item in the list is an attribute path inside `hydraJobs` in the 
        # form of a dot-string. For example:
        #   [ "packages.my-attrs.my-nested-attr.my-pkg" "checks.exclude-me" ]
        # This field is optional.
        # This field default to the empty list.
        blacklistedHydraJobs = [ ];

        # Whether to run the pre-commit-check in CI, which mostly runs the
        # formatters. In general you want this to be true, but you can disable 
        # it temporarily while migrating to IOGX if you find that the formatters 
        # are producing large diffs on the source files.
        # This field is optional.
        # This field default to true.
        enableHydraPreCommitCheck = true;

        # Whether to include build artifacts for a read-the-docs-site.
        # You should set this field to false if you repo does not support
        # read-the-docs. If this field is set to false, then the following 
        # fields have no effect: 
        #   readTheDocsSiteRoot
        #   readTheDocsHaddockPrologue
        #   readTheDocsExtraHaddockPackages
        # This field is optional.
        # This field default to false.
        includeReadTheDocsSite = false;

        # The folder containing the read-the-docs python project.
        # You should set this value to something like:
        # `readTheDocsSiteRoot = ./doc/read-the-docs`
        # This field is optional.
        # This field default to null, which means: read-the-docs not available.
        readTheDocsSiteRoot = null;

        # A string to be appended to your haddock index page.
        # Haddock is included in the read-the-docs site.
        # This field is optional.
        # This field default to "", which means: do not add a prologue.
        readTheDocsHaddockPrologue = "";

        # A function taking the project's haskell.nix package set and returning 
        # a possibly empty attrset of extra haskell packages.
        # The haddock for the returned packages will be included in the final 
        # haddock for this project. 
        # The returned attrset must be of the form: 
        # `{ haskell-package-name: haskell-package }`
        # In general you want to include IOG-specific haskell dependencies here.
        # For example, in the haddock for plutus-apps you will want to include
        # the haddock for some plutus-core components, in which case you would 
        # set this value like this:
        # readTheDocsExtraHaddockPackages = hsPkgs: {
        #   inherit (hsPkgs) 
        #     plutus-core plutus-tx plutus-tx-plugin 
        #     plutus-ledger-api quickcheck-contractmodel
        # }
        # This field is optional.
        # This field default to a noop, which means: do not add extra packages.
        readTheDocsExtraHaddockPackages = _: { };
      };
    in
    inputs.iogx.mkFlake inputs flakeopts;


  nixConfig = {

    # Do not remove these two substitures, but add to them if you wish.
    extra-substituters = [
      "https://cache.iog.io"
      "https://cache.zw3rk.com"
    ];

    # Do not remove these two public-keys, but add to them if you wish.
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "loony-tools:pr9m4BkM/5/eSTZlkQyRt57Jz7OMBxNSUiMC4FkcNfk="
    ];

    # Do not remove this: it's needed by haskell.nix.
    allow-import-from-derivation = true;
  };
}
