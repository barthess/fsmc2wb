#!/bin/bash

rm -f test_vectors/*
g++ -O2 --std=c++11 adr_test_gen.cpp && ./a.out
