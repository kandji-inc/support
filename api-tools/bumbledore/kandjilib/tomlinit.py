#!/usr/local/bin/python3

# Github: @captam3rica

"""toml_init.py
A script for importing and utilizing MDM API settings from a TOML
configuration file.
"""

__version__ = "0.3.0"

import logging
import pathlib
import sys

import toml


TOML_FILE = pathlib.Path(pathlib.Path.cwd()).joinpath("config.toml")


def parse_toml_file(toml_file):
    """Returns parsed toml data."""
    try:
        return toml.load(toml_file)
    except KeyError as error:
        sys.exit(error)


def customer_name(toml_data):
    """Return the customer name from the toml data file"""
    return toml_data["customer"]["customer_name"]


def base_url(toml_data):
    """Returns the MDM console URL from the TOML config"""
    return toml_data["mdm_info"]["base_url"]


def mdm_vendor(toml_data):
    """Returns the MDM vendor from the TOML config"""
    vendor = toml_data["mdm_info"]["vendor"]
    return vendor


def build_api_headers(
    toml_data,
):
    """Returns API header information from TOML config"""

    if mdm_vendor(toml_data) in ("Kandji", "kandji", "Kandji.io", "kandji.io", "🐝"):
        # Token key authnentication in use
        headers = {
            "Authorization": toml_data["api_info"]["authorization"],
            "Accept": toml_data["api_info"]["accept"],
            "Content-Type": toml_data["api_info"]["content_type"],
            "Cache-Control": toml_data["api_info"]["cache_control"],
        }

    return headers


def log_configuration(toml_data):
    """Pull the default log configuration set in the mdm-info.foml file."""
    try:
        log_file_path = toml_data["log_config"]["log_file_path"]
        return log_file_path
    except KeyError as error:
        default_log_path = pathlib.Path("/Library").joinpath("Logs")
        logging.info("Log file path is not configured: %s", error)
        logging.info("Setting the log path to the default path %s", default_log_path)
        return default_log_path
