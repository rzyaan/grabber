#!/usr/bin/python3

from fastapi import Form
from pydantic import BaseModel

class EmployeeForm(BaseModel):
    first_name: str 
    family_name: str
    badge_number: str
