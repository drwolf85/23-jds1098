# -*- coding: utf-8 -*-
"""
Created on Thu Feb 23 13:45:45 2023

@author: sartlu
"""
import pandas as pd

for county in [17105, 17113, 31135, 38075, 39149, 48189]:
    fn = f"../dta/double/alldata_{county}.feather"
    dt = pd.read_feather(fn)
    dt = dt.astype('uint8')
    fn = f"../dta/alldata_{county}.feather"
    dt.to_feather(fn)
