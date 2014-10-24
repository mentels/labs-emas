labs-emas
=========
[![Build Status](https://travis-ci.org/ParaPhraseAGH/labs-emas.svg?branch=master "Build Status")](https://travis-ci.org/ParaPhraseAGH/labs-emas)

This repository provides custom operators for the [EMAS algorithm](https://github.com/ParaPhraseAGH/erlang-emas), which try to find [Low Autocorrelation Binary Sequences](http://militzer.berkeley.edu/sequences.html).

## Dependencies

To run the project on your machine you need:

* [Erlang (R17 or later)](http://www.erlang.org/)
* [Git](http://git-scm.com/)

## How to build the project

First you need to clone the repository:

    > git clone https://github.com/ParaPhraseAGH/labs-emas.git
    > cd labs-emas/

To build the project you should use the Makefile command:

    > make deps
    
Which will download and compile all necessary dependencies and the project itself.

## How to run the project

To start a VM where you can run the application, first make sure that you are in the main project's folder:

    > cd labs-emas/
    
Then you can run:

    > make shell
    
which will compile the sources and start the Erlang VM with appropriate flags.

To run the application you can type:

    1> emas:start(mas_concurrent, 10000, [{genetic_ops, labs_ops}]).
  
which will start the algorithm. The word `emas` is the name of the main module of our usecase. The atom `mas_concurrent` defines the version of the program which will be used to execute the program. Currently you can choose from `mas_concurrent`, `mas_hybrid`, `mas_skel` and `mas_sequential` versions.

The second parameter is the expected time of execution in miliseconds and the third argument is a list of simulation properties that can be redefined from the command line. The default values are stored in `~/deps/mas/etc/emas.config` file and can be freely edited. In this list we include a tuple with a name of the operators module.

Another list can be also provided as a starting argument:

    3> emas:start(mas_concurrent, 10000, [{genetic_ops, labs_ops}], [{islands, 8}]).
    
which overwrites the parameters of the MAS framework. The list of properties and their default values can be found in the `~/deps/mas/etc/mas.config` file and can be freely edited as well.

By default, the program will write all its results to stdout, so you can see if everything is configured correctly.
