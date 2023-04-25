#!/bin/bash

for rate in `seq 1 1 10`; do
    ./MaSim -i cellular.yml -r CellularReporter -j $rate    
done