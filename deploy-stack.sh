#!/bin/bash

# before deploying
    # AUTHORIZATION PROBLEM
    # docker login quay.io
    # gcloud auth login

    # VOLUME MOUNTING PROBLEM (WSL2)
    sudo mkdir /mnt/docker_data
    sudo mount -t drvfs '\\wsl$\docker-desktop-data\data\docker' /mnt/docker_data

# Deploying
docker compose up -d 

# MEET THIS PROBLEM: error getting credentials - err: exit status 1, out: ''
# In ~/.docker/config.json change credsStore to credStore
