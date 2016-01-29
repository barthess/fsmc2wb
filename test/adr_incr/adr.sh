#!/bin/bash

rm -f stim/*
rmdir stim
mkdir stim

g++ -O0 --std=c++11 adr_test_gen.cpp && ./a.out
