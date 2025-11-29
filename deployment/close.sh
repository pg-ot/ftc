#!/bin/bash
docker exec substation-control-ied sh -c 'kill -12 $(pgrep control_ied)'
