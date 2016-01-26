#!/bin/bash

rm -f stim/*
rmdir stim
mkdir stim

g++ -O0 --std=c++11 sum_test_gen.cpp -o sum_test_gen.elf && ./sum_test_gen.elf
