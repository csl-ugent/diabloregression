Introduction
============

The regression.py script is a generic, configurable regression testing utility.
Executing it without any parameters shows a help screen explaining all
parameters.

An example of its usage is shown below:

  ./regression.py -c arm/spec2006.conf \
  -d /home/jmaebe/private/diablo/diablo \
  -p diablo \
  -o "-Z -S" -R rep.html -t
