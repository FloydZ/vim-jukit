{ pkgs ? import <nixpkgs> {} }:
let
  myPython = pkgs.python3;
  pythonPackages = pkgs.python3Packages;
  pythonWithPkgs = myPython.withPackages (pythonPkgs: with pythonPkgs; [
    ipython
    pip
    setuptools
    virtualenv
    wheel
  ]);

  # add the needed packages here
  extraBuildInputs = with pkgs; [
    myPython
    pythonPackages.numpy
    pythonPackages.pytest
    pythonPackages.pylint
    pythonPackages.ipython
    pythonPackages.matplotlib
    pythonPackages.nbconvert

    # dev
    sage
    ruff
    jetbrains.pycharm-community
  ] ++ (lib.optionals pkgs.stdenv.isLinux ([
  ]));
in
let
  buildInputs  = with pkgs; [
      clang
      gtest
  ] ++ extraBuildInputs;
  lib-path = with pkgs; lib.makeLibraryPath buildInputs;
  shell = pkgs.mkShell {
    buildInputs = [
       # my python and packages
        pythonWithPkgs
        
        # other packages needed for compiling python libs
        pkgs.readline
        pkgs.libffi
        pkgs.openssl
        pkgs.clang
  
        # unfortunately needed because of messing with LD_LIBRARY_PATH below
        pkgs.git
        pkgs.openssh
        pkgs.rsync
    ] ++ extraBuildInputs;
    shellHook = ''
        # Allow the use of wheels.
        SOURCE_DATE_EPOCH=$(date +%s)
        # Augment the dynamic linker path
        export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${lib-path}"
        # Setup the virtual environment if it doesn't already exist.
        VENV=.venv
        if test ! -d $VENV; then
          virtualenv $VENV
        fi
        source ./$VENV/bin/activate
        export PYTHONPATH=$PYTHONPATH:`pwd`/$VENV/${myPython.sitePackages}/
        nvim --cmd 'set rtp+=./'
    '';
  };
in shell
