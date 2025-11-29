#!/bin/bash
docker exec substation-control-ied sh -c 'kill -10 $(pgrep control_ied)'
