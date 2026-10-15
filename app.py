from typing import Annotated

from fastapi import FastAPI, Request, HTTPException, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from pydantic import BaseModel

from sqlmodel import SQLModel, create_engine, Session, select
import json

from models import Ordinateur 
from forms import EmployeeForm

class HardwareModel(BaseModel):
    HOSTNAME: str
    MAC_ADDRESS: str
    MB_SERIAL: str
    CHASSIS_SERIAL: str
    CPU: str
    CPU_ID: str
    CPU_CORES_NUMBER: str
    CPU_THREADS_NUMBER: str
    CPU_FREQUENCY_MIN: str
    CPU_FREQUENCY_CUR: str
    CPU_FREQUENCY_MAX: str
    GPU_MODEL: str
    RAM_SLOTS_NUMBER: str
    RAM_NUMBER: str
    RAM_SIZE: str
    RAM_GEN: str
    STOCKAGE_TOTAL: str


class SoftwareModel(BaseModel):
    OS: str
    ARCH: str
    DESKTOP: str
    WM: str
    KERNEL: str


class ComputerPayload(BaseModel):
    HARDWARE: HardwareModel
    SOFTWARE: SoftwareModel

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

sqlite_url = f"sqlite:///mydb.db"
engine = create_engine(sqlite_url)
SQLModel.metadata.create_all(engine)

@app.get("/employee/create")
async def get_employee_form(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="employee_form.html",
        success=True
        )

@app.post("/employee/create", response_class=RedirectResponse)
async def submit_employee_form(data: Annotated[EmployeeForm, Form()]):
    print(f"data obtained is {data}")
    with Session(engine) as session:
        employee = Employee(
            first_name=data.fname, 
            family_name=data.lname
        )
        session.add(employee)
        session.commit()
        session.refresh(employee)
    return RedirectReponse("/employees")

@app.get("/employees", response_class=HTMLResponse)
async def get_employees(request: Request):
    with Session(engine) as session:
        statement = select(Employee)
        employees = session.exec(statement).all()

        return templates.TemplateResponse(
            request=request, name="employees.html", 
                 context={"employees": employees})

@app.get("/ordi/{ordi_id}", response_class=HTMLResponse)
async def get_ordi1_info(request: Request, ordi_id: int):
    with Session(engine) as session:
        statement = select(Ordinateur).where( Ordinateur.id == ordi_id )
        this_ordi = session.exec(statement).first()

        return templates.TemplateResponse(
            request=request, name="ordi.html", context={"ordi": this_ordi}
        )

@app.post("/endpoint")
async def receive_info(payload: ComputerPayload):

    print("Infos reçues :", payload)

    ordi1 = Ordinateur(
        mb_serial=payload.HARDWARE.MB_SERIAL,
        chassis_serial=payload.HARDWARE.CHASSIS_SERIAL,
        cpu=payload.HARDWARE.CPU,
        cpu_id=payload.HARDWARE.CPU_ID,
        cpu_cores_number=payload.HARDWARE.CPU_CORES_NUMBER,
        cpu_threads_number=payload.HARDWARE.CPU_THREADS_NUMBER,
        cpu_frequency_min=payload.HARDWARE.CPU_FREQUENCY_MIN,
        cpu_frequency_cur=payload.HARDWARE.CPU_FREQUENCY_CUR,
        cpu_frequency_max=payload.HARDWARE.CPU_FREQUENCY_MAX,
        gpu_model=payload.HARDWARE.GPU_MODEL,
        ram_slots_number=payload.HARDWARE.RAM_SLOTS_NUMBER,
        ram_number=payload.HARDWARE.RAM_NUMBER,
        ram_gen=payload.HARDWARE.RAM_GEN,
        hostname=payload.HARDWARE.HOSTNAME,
        os=payload.SOFTWARE.OS,
        arch=payload.SOFTWARE.ARCH,
        desktop=payload.SOFTWARE.DESKTOP,
        wm=payload.SOFTWARE.WM,
        kernel=payload.SOFTWARE.KERNEL,
        mac_address=payload.HARDWARE.MAC_ADDRESS,
        ram_size=payload.HARDWARE.RAM_SIZE,
        stockage_total=payload.HARDWARE.STOCKAGE_TOTAL,
    )

    with Session(engine) as session:
        session.add(ordi1)
        session.commit()
        session.refresh(ordi1)

    return {"status": "ok", "ordi_id": ordi1.id}
    # # Lire le body brut
    # body = await request.body()
    # print(body)

    # # Parser le JSON
    # try:
    #     data = json.loads(body)
    # except json.JSONDecodeError:
    #     raise HTTPException(status_code=400, detail="Invalid JSON")
    
    # # Debug
    # print("Infos recues :", data)
    
    # ordi1 = Ordinateur()

    # ordi1.mb_serial = data['HARDWARE']['mb_serial']
    # ordi1.hostname = data['HARDWARE']['hostname']
    # print(f"Le serial de la mb est {ordi1.mb_serial}")
    # print(f"Le hostname de l'ordi est {ordi1.hostname}")

    # session = Session(engine)
    # session.add(ordi1)
    # session.commit()

    # return({"status": "ok"})