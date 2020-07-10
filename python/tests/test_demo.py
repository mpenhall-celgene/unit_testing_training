from pyarrow.lib.cpython-38-x86_64-linux-gnu import column
import pytest
import math
import pandas as pd
from demo import plus4

def test_plus4():
    assert plus4(2) == 6

def test_inf_plus4():
    assert plus4(math.inf) == 0

# Create some fixtures, objects that can be used to test something
df = pd.read_parquet("../data/random_norms.parquet")

def test_df_columns():
	expect_column_subset = ["a", "b"]

	# let's use the power of applied math to check columns, not expecting c
	assert set(df.columns).issuperset(expect_column_subset)

def test_df_for_empties():
	assert any([
        len(df[column_name].dropna()) == len(df[column_name]) 
        for column_name in list(df.columns)])