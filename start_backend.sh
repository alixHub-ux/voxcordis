#!/bin/bash
cd /home/carine/voxcordis/voxcordis-api
exec ./venv/bin/uvicorn main:app --host 0.0.0.0 --port 7860 > /tmp/backend.log 2>&1
