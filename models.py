#!/usr/bin/python3
import configparser
import requests

from sqlmodel import SQLModel, Field, Relationship

class EmployeeOrdi(SQLModel, table=True):
    employee_id: int | None = Field(default=None,
    	foreign_key="employee.id",
    	primary_key=True
    )
    ordi_id: int | None = Field(default=None,
        foreign_key="ordinateur.id",
        primary_key=True
    )


class Employee(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    first_name: str = Field(index=True)
    family_name: str = Field(index=True)
    badge_number: str = Field(index=True)
    ordis: list["Ordinateur"] = Relationship(back_populates="employees", link_model=EmployeeOrdi)

class Ordinateur(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)

    employees: list["Employee"] = Relationship(back_populates="ordis", link_model=EmployeeOrdi)

    mb_serial : str = Field(index=True) 
    chassis_serial : str = Field(default= "")
    cpu : str = Field(default= "")
    cpu_id : str = Field(default= "")
    cpu_cores_number : str = Field(default= "")
    cpu_threads_number : str = Field(default= "")
    cpu_frequency_min : str = Field(default= "")
    cpu_frequency_cur : str = Field(default= "")
    cpu_frequency_max : str = Field(default= "")
    gpu_model : str = Field(default= "")
    ram_slots_number : str = Field(default= "")
    ram_number : str = Field(default= "")
    ram_gen : str = Field(default= "")
    hostname : str = Field(default= "")

    os  : str = Field(default= "")
    arch  : str = Field(default= "")
    desktop  : str = Field(default= "")
    wm  : str = Field(default= "")
    kernel  : str = Field(default= "")