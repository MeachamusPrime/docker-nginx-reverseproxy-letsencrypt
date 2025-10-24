#!/bin/bash

# Generating self-signed certificates for each host, mandatory for Nginx and LE
# to execute properly
services=$(env | grep SERVICE_HOST_ | cut -d "=" -f1 | sed 's/^SERVICE_HOST_//')

# Create nginx configuration
for service in $services
do
  ROOT_SET=
  host="SERVICE_HOST_$service"
  proxy="SERVICE_PROXY_$service"
  if [ -z "${!proxy}" ]; then
    proxies=$(env | grep ${proxy}_ | cut -d "=" -f1 | sed "s/^${proxy}_//")
    if [ -z "$proxies" ]; then
      continue;
    fi
    FILE_NAME=$(echo $service | tr '[:upper:]' '[:lower:]').conf
    echo "Generating nginx configuration file \"${FILE_NAME}\" for \"${!host}\"."
    DOMAIN=${!host} envsubst '$DOMAIN' < multiservice.conf.header > "${FILE_NAME}"
    for subproxy in $proxies
    do
      total_proxy="${proxy}_$subproxy"
      location="SERVICE_LOCATION_${service}_$subproxy"
      if [ -z "${!total_proxy}" ]; then
        continue;
      fi
      if [ -z "${!location}" ]; then
        if [ -z "${ROOT_SET}" ]; then
          ROOT_SET=TRUE
        else
          continue;
        fi
      fi
      # output to configuration file
      LOCATION=${!location} PROXY=${!total_proxy} envsubst '$PROXY,$LOCATION' < multiservice.conf.template >> "${FILE_NAME}"
    done
    DOMAIN=${!host} envsubst '$DOMAIN' < multiservice.conf.footer >> "${FILE_NAME}"
    continue;
  fi
  FILE_NAME=$(echo $service | tr '[:upper:]' '[:lower:]').conf
  echo "Generating nginx configuration file \"${FILE_NAME}\" for \"${!host}\"."
  DOMAIN=${!host} PROXY=${!proxy} envsubst '$PROXY,$DOMAIN' < service.conf.template > "${FILE_NAME}"
done
