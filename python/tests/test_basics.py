import pytest
import math
from basics import plus4

def test_plus4():
    assert plus4(2) == 6

def test_inf_plus4():
    assert plus4(math.inf) == 0