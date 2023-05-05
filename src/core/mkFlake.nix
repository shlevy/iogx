{ inputs, systemized-inputs, flakeopts, pkgs, l, iogx, ... }:

let
  # Rename the outputs of the flake generated by haskell.nix:mkFlake.
  # haskell.nix uses cons (:) but we prefer dashes.
  # We also add prefixes/suffixes agains: the current compiler (ghc), whether 
  # haskell profiling is enabled (profiled) and whether we are cross building on
  # Windows (cross).
  # renameFlakeOutputs will be called 4 times for each compiler, for example:
  # marlowe:runtime-web:lib:server
  # 1. ghc8107-marlowe-runtime-web-lib-server-profiled
  # 2. ghc8107-marlowe-runtime-web-lib-server
  # 3. ghc8107-mingwW64-marlowe-runtime-web-lib-server-profiled
  # 4. ghc8107-mingwW64-marlowe-runtime-web-lib-server
  renameFlakeOutputs = { flake, ghc, cross, profiled }:
    let
      replaceCons = l.replaceStrings [ ":" ] [ "-" ];

      prefixName = name:
        let
          cross' = l.optionalString cross "-mingwW64";
          name' = "-${replaceCons name}";
          profiled' = l.optionalString profiled "-profiled";
        in
        l.nameValuePair "${ghc}${cross'}${name'}${profiled'}";

      prefixGroup = group: attrs:
        # If we are renaming hydraJobs, then we need to recurse.
        if group == "hydraJobs" then
          l.mapAttrs prefixGroup attrs
        # We don't want to rename this stuff because they are not attrsets.
        else if group == "roots" || group == "plan-nix" || group == "coverage" then
          attrs
        else
          l.mapAttrs' prefixName attrs;
    in
    l.mapAttrs prefixGroup flake;


  # Make a flake against the current GHC, with or without cross compilation 
  # and/or profiling enabled.
  # This function actually evaluates the haskell.nix project and calls the 
  # mkFlake utility function, which does most of the heavy lifting for us.
  # The returned flake has "dummy" devShells that will be augmented later.
  # The returned flake has already been renamed (see renameFlakeOutputs).
  mkFlakeFor = { ghc, cross, profiled }:
    let
      project' = import flakeopts.haskellProjectFile {
        # NOTE: using flakeopts
        inherit inputs systemized-inputs flakeopts pkgs ghc;
        deferPluginErrors = false;
        enableProfiling = profiled;
      };

      project = if cross then project'.projectCross.mingwW64 else project';

      flake = pkgs.haskell-nix.haskellLib.mkFlake project {
        # TODO remove withHoogle = false; and set it manually to all projects.
        # NOTE: we append the ghc & project to the shell so that we can retrieve 
        # them later when making the devShell.
        devShell = project.shellFor { withHoogle = false; } // { inherit ghc project; };
      };
    in
    renameFlakeOutputs { inherit ghc cross profiled flake; };


  # For each compiler we call haskell.nix:mkFlake against a matrix of projects,
  # and merge all the flakes together. This is safe because each configuration
  # uses distinct prefixes and suffixes for the derivation names. 
  # The final flake contains:
  # { packages, checks, devShells, devShell, roots, plan-nix, coverage }
  mkFlakeForCompiler = ghc:
    let
      unprofiled-flake =
        mkFlakeFor { inherit ghc; profiled = false; cross = false; };
      profiled-flake =
        mkFlakeFor { inherit ghc; profiled = true; cross = false; };
      cross-unprofiled-flake =
        mkFlakeFor { inherit ghc; profiled = false; cross = true; };
      cross-profiled-flake =
        mkFlakeFor { inherit ghc; profiled = true; cross = true; };

      native-flakes = [ unprofiled-flake profiled-flake ];
      should-cross-compile = toString flakeopts.haskellCrossSystem == pkgs.stdenv.system;
      cross-flakes = [ cross-unprofiled-flake cross-profiled-flake ];
      all-flakes = native-flakes ++ l.optionals should-cross-compile cross-flakes;
    in
    l.recursiveUpdateMany all-flakes;


  # The user most likely wants to add custom or standard flake outputs.
  # We merge all those outputs with ours. 
  # TODO what to do about hydraJobs and ciJobs?
  # TODO detect collisions.
  addUserPerSystemOutputs = flake:
    let
      flake' = import flakeopts.perSystemOutputsFile # NOTE: using flakeopts 
        { inherit inputs systemized-inputs flakeopts pkgs; };
    in
    if flakeopts.perSystemOutputsFile == null then
      flake
    else
      l.recursiveUpdate flake flake';


  # If required, we add the read-the-docs sites to the packages outputs.
  addReadTheDocsPackages = flake:
    if flakeopts.includeReadTheDocsSite then
      l.recursiveUpdate flake { packages.readthedocs = iogx.readthedocs.sites; }
    else
      flake;

  # This function does 3 things:
  # 1. Augment all "dummy" devShells generated by haskell.nix:mkFlake
  # 2. Add the default devShell, since all existing devShells in the 
  #    flake are prefixed by the compiler name (e.g. ghc8107-default).
  # 3. Remove the legacy devShell from the flake.
  addDevShells = flake':
    let
      addDefaultDevShell = flake:
        let ghc = "${flakeopts.defaultHaskellCompiler}-default";
        in l.recursiveUpdate flake { devShells.default = flake.devShells.${ghc}; };

      addPrefixedDevShells = flake:
        let mkDevShell = _: shell: iogx.core.mkDevShell.mkDevShell { inherit shell flake; };
        in l.recursiveUpdate flake { devShells = l.mapAttrs mkDevShell flake.devShells; };

      removeLegacyDevShell = flake: removeAttrs flake [ "devShell" ];
    in
    l.composeManyLeft [
      addPrefixedDevShells
      addDefaultDevShell
      removeLegacyDevShell
    ]
      flake';


  # The hydraJobs require special care and so we handle them separately.
  addHydraJobs = flake:
    let
      flake' = rec {
        hydraJobs = iogx.core.mkHydraJobs { inherit flake; };
        ciJobs = hydraJobs;
      };
    in
    if flakeopts.includeHydraJobs then
      flake // flake'
    else
      flake;


  # When migrating to IOGX, one might want to keep the old flake outputs 
  # as well as the new ones. An easy way to do this is to prefix (nest) each 
  # output group { packages, apps, <custom>, devShells, ... } with a custom 
  # name.
  prefixOutputs = flake:
    if flakeopts.flakeOutputsPrefix != "" then
      l.nestAttrs flake [ flakeopts.flakeOutputsPrefix ]
    else
      flake;


  # Generate a flake for each GHC, and merge them all into one.
  mergeHaskellFlakes = _:
    let all-flakes = map mkFlakeForCompiler flakeopts.haskellCompilers;
    in l.recursiveUpdateMany all-flakes;


  final-flake =
    l.composeManyLeft [
      # First generate the merged flake from the compiler set.
      mergeHaskellFlakes
      # Then add the readthedocs packages, if needed
      addReadTheDocsPackages
      # Then we add the devShells
      addDevShells
      # Then add the user outputs
      addUserPerSystemOutputs
      # # Then the hydraJobs
      addHydraJobs
      # Finally prefix everything if needed.
      prefixOutputs
    ]
      { };

in
final-flake
