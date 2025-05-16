#!/bin/bash

function LOG_INFO
    {
    echo -e "\e[38;5;22mINFO:\e[0m $@"
    }

function LOG_ERROR
    {
    echo -e "\e[38;5;1mERROR:\e[0m $@" 1>&2
    }

function LOG_WARNING
    {
    echo -e "\e[38;5;3mWARNING:\e[0m  $@" 1>&2
    }
