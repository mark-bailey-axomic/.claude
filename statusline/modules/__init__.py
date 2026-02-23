from .git import mod_git
from .model import mod_model
from .reset import mod_reset
from .daily import mod_daily
from .weekly import mod_weekly
from .sandbox import mod_sandbox

MODULES = {
    "git": mod_git,
    "model": mod_model,
    "reset": mod_reset,
    "daily": mod_daily,
    "weekly": mod_weekly,
    "sandbox": mod_sandbox,
}
