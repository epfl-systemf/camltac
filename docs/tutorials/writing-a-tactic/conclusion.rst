Conclusion
==========

This tutorial has covered the basic parts of Camltac:

* how to define new tactics and modules;
* how to run Camltac tactics;
* how to use pattern-matching;
* how to export Camltac tactics to Ltac2.

Going further
-------------

Here are a few exercises you could try:

* Filter the list of proposed lemmas to those that can be indeed applied using `apply`, using backtracking;
* Implement `exact?`, a version of `apply?` that only suggests lemmas that can close the goal;
* Modify the search pattern to include variables in the environment.

Where to go from here
---------------------

* The :ref:`how-to guides <howtos>` cover most of the practical aspects of using Camltac.
* The :ref:`reference <reference>` section describes Camltac command in more details.
* The :ref:`explanation <explanation>` section explains how Camltac works.
