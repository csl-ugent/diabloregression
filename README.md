Introduction
============

This repository contains data to set up Diablo regression testing
infrastructure.

Overview
========

Every subdirectory mentioned below contains its own README.txt describing its
contains in more detail. The included subdirectories are:

* speccpu2006: contains scripts and data to set up SPEC CPU2006 for regression
testing

* mibench: contains script and data to set up MiBench for regression testing

* common: common scripts/data
 - common/regression-main: Python script containing the generic regression
     testing framework. Usable after installing one or more of the
     aforementioned regression testing suites.
 - common/fakediablo: Shell script that can be passed as "diablo" binary to
     regression.py to test the original binary
