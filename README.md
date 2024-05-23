# GetEnv
This script is designed to land secure env variables to a Makefile for a brief amount of time, so it can include the key-value pairs.  
Normally 1 second is enough, but configuration allows 2 seconds to accomodate multiple / large key-value-pair passes.

## Pre-requisites, expectations
- The Makefile is expected to be ran by a low-privileged user.
- The getenv.sh is a wrapper for getenv-worker. Only getenv.sh gets access in sudoers, so contents of getenv-worker rmains secure.
- Getenv requires the current path of the Makefile to be passed, and the GROUP name or id to own the returned variables file.
- Getenv returns a unique ID for the Makefile, so it can pick up the vars file immediately
- Getenv copies the env file as `.env_<CALLER>.<UNIQUE_ID>`, where caller is the name of the directory Makefile sits inside (in case of below example: `traefik`).
- Getenv ensures env file is removed (shred -u) after 2 seconds - so pick up immediately.

## Setup
Sudoers configuration for the wrapper: /etc/sudoers.d/docker_secure_env_vars
```
docker-user ALL=(ALL) NOPASSWD: /home/docker-user/_common/getenv/getenv.sh
```

The secure env file: ./\_common/getenv/env.traefik
```
TRAEFIK_NETWORK=value
```

Makefile for service (s): ./traefik/Makefile:
```
SHELL=/bin/bash
include ./.env_traefik.$(shell sudo ../_common/getenv/getenv.sh $(shell pwd)/$(lastword $(MAKEFILE_LIST)) $(shell id -gn))

env-test:
        @echo $(TRAEFIK_NETWORK)
```

## Anatomy:
- Script identifies caller process
- Last part of caller process is matched against the env variables available to be offered
- If there is a set of variables assigned for that process bit, it will be offered.

- New random gets created
- 

## Debugging:
All events are being logged to syslog. 
Example:
```
Jan 1 20:00:01 host getenv: [authorized] traefik
Jan 1 20:00:01 host getenv: [traefik] assigning env vars with id 296622928631295
Jan 1 20:00:03 host getenv: [traefik] shredding env vars with id 27005198613881 after 2 second(s).
```

Env variables not found will be marked as "unauthorized".  
An attempt has been made to log all errors.

## Security recommendation
Do not allow the Makefile using this solution to be overwritten, otherwise a custom script may simply fetch the variables with no issue.
