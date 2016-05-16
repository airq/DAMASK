#!/usr/bin/env bash

for geom in "$@"
do
  geom_toTable \
  < $geom \
  | \
  vtk_rectilinearGrid > ${geom%.*}.vtk

  geom_toTable \
  < $geom \
  | \
  vtk_addRectilinearGridData \
    --scalar microstructure \
    --inplace \
    --vtk ${geom%.*}.vtk
  rm ${geom%.*}.vtk
done