#!/usr/bin/env python2
# -*- coding: UTF-8 no BOM -*-

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import numpy as np

ext = [Extension("corientation", ["corientation.pyx"],
                 include_dirs=[np.get_include()])]

setup(
      name="corientation",
      include_dirs=[np.get_include()],
      cmdclass = {'build_ext': build_ext},
      ext_modules=ext
)