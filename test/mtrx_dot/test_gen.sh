#!/bin/bash

rm -f stim/*
rmdir stim
mkdir stim

g++ -O0 -Wall -Wextra --std=c++11 mtrx_test_gen.cpp && ./a.out
