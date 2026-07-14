from pydantic import BaseModel

class PredictionResponse(BaseModel):
    risk_level   : str
    risk_label   : str
    color_code   : str
    title        : str
    message      : str
    advice       : str
    reliability  : str
    disclaimer   : str