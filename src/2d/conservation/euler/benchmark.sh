#!/bin/bash

./dgsupersonic -b -t 100000 -n 1 ../../cpu-conservation/euler/supersonic/mesh/A.pmsh
./dgsupersonic -b -t 50000 -n 2 ../../cpu-conservation/euler/supersonic/mesh/A.pmsh
./dgsupersonic -b -t 40000 -n 3 ../../cpu-conservation/euler/supersonic/mesh/A.pmsh
./dgsupersonic -b -t 30000 -n 4 ../../cpu-conservation/euler/supersonic/mesh/A.pmsh
./dgsupersonic -b -t 20000 -n 5 ../../cpu-conservation/euler/supersonic/mesh/A.pmsh

./dgsupersonic -b -t 80000 -n 1 ../../cpu-conservation/euler/supersonic/mesh/B.pmsh
./dgsupersonic -b -t 60000 -n 2 ../../cpu-conservation/euler/supersonic/mesh/B.pmsh
./dgsupersonic -b -t 30000 -n 3 ../../cpu-conservation/euler/supersonic/mesh/B.pmsh
./dgsupersonic -b -t 15000 -n 4 ../../cpu-conservation/euler/supersonic/mesh/B.pmsh
./dgsupersonic -b -t 10000 -n 5 ../../cpu-conservation/euler/supersonic/mesh/B.pmsh

./dgsupersonic -b -t 40000 -n 1 ../../cpu-conservation/euler/supersonic/mesh/C.pmsh
./dgsupersonic -b -t 30000 -n 2 ../../cpu-conservation/euler/supersonic/mesh/C.pmsh
./dgsupersonic -b -t 15000 -n 3 ../../cpu-conservation/euler/supersonic/mesh/C.pmsh
./dgsupersonic -b -t 8000 -n 4 ../../cpu-conservation/euler/supersonic/mesh/C.pmsh
./dgsupersonic -b -t 1000 -n 5 ../../cpu-conservation/euler/supersonic/mesh/C.pmsh

./dgsupersonic -b -t 20000 -n 1 ../../cpu-conservation/euler/supersonic/mesh/D.pmsh
./dgsupersonic -b -t 10000 -n 2 ../../cpu-conservation/euler/supersonic/mesh/D.pmsh
./dgsupersonic -b -t 5000 -n 3 ../../cpu-conservation/euler/supersonic/mesh/D.pmsh
./dgsupersonic -b -t 2000 -n 4 ../../cpu-conservation/euler/supersonic/mesh/D.pmsh
./dgsupersonic -b -t 1000 -n 5 ../../cpu-conservation/euler/supersonic/mesh/D.pmsh

./dgsupersonic -b -t 10000 -n 1 ../../cpu-conservation/euler/supersonic/mesh/E.pmsh
./dgsupersonic -b -t 5000 -n 2 ../../cpu-conservation/euler/supersonic/mesh/E.pmsh
./dgsupersonic -b -t 2000 -n 3 ../../cpu-conservation/euler/supersonic/mesh/E.pmsh
./dgsupersonic -b -t 1000 -n 4 ../../cpu-conservation/euler/supersonic/mesh/E.pmsh
./dgsupersonic -b -t 500 -n 5 ../../cpu-conservation/euler/supersonic/mesh/E.pmsh

./dgsupersonic -b -t 5000 -n 1 ../../cpu-conservation/euler/supersonic/mesh/F.pmsh
./dgsupersonic -b -t 2000 -n 2 ../../cpu-conservation/euler/supersonic/mesh/F.pmsh
./dgsupersonic -b -t 1000 -n 3 ../../cpu-conservation/euler/supersonic/mesh/F.pmsh
./dgsupersonic -b -t 500 -n 4 ../../cpu-conservation/euler/supersonic/mesh/F.pmsh
./dgsupersonic -b -t 200 -n 5 ../../cpu-conservation/euler/supersonic/mesh/F.pmsh