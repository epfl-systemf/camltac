How to use Camltac with Makefiles
=================================

Using Camltac with Makefiles should work out-of-the-box using no additional commands beyond the regular build process, since Camltac takes care of calling the OCaml compiler by itself.

If you'd like to create a package that exposes Camltac modules to users, make sure to include the `.camltac` folder in your distribution (see also the `Dune setup <Setup Dune.rst>`_).
