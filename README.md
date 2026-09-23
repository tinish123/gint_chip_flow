# GINT Chip Design Flow

This repository contains the Hammer-based digital implementation flow used for a 55-nm mixed-signal CMOS chip. The flow covers synthesis and physical design using Cadence Genus and Innovus, with custom Hammer hooks for project-specific implementation steps and mixed-signal macro integration.

The repository is intended primarily as a reference for the structure and automation of the ASIC design flow rather than as a fully portable, turnkey tapeout environment.

## Flow Structure

The flow is built around [Hammer](https://github.com/ucb-bar/hammer) and uses:

* `Makefile` — top-level flow orchestration
* `gint-vlsi` — custom Hammer `CLIDriver` with project-specific hooks
* `tools.yml` — EDA tool configuration
* `gf55lpx.yml` — GF 55LPx technology configuration
* `env.yml` — environment configuration
* `defaults.yml` — common technology/design defaults
* `*-design.yml` — design-specific Hammer configuration
* `build/` — generated synthesis and physical-design outputs

Hammer generates the underlying tool scripts and manages the dependencies between synthesis, place-and-route, and related implementation stages.

## Setup

A working installation of **Hammer** is required.

The flow was developed using a GlobalFoundries 55LPx PDK together with Cadence Genus and Innovus. Before running the flow, the configuration files must be adapted to the local environment, including paths to:

* Hammer and EDA tool installations
* technology/PDK files
* standard-cell libraries
* timing libraries
* RC extraction technology files
* custom SRAM/analog macro LEF, Liberty, GDS, and related views

A typical Makefile invocation follows the form:

```bash
make TARGET=<design> <target>
```

The available targets and exact configuration depend on the Hammer setup and design configuration.

## Technology-Specific Files

Several paths and references in the configuration and Python/Tcl hooks are specific to the environment in which this chip was designed.

In particular, the repository may reference proprietary:

* GlobalFoundries 55LPx PDK files
* ARM standard-cell libraries
* custom SRAM and mixed-signal macro views
* extraction/signoff technology files
* commercial EDA installations

These files cannot be distributed due to licensing and proprietary-design restrictions and are therefore **not included in this repository**.

Users wishing to adapt the flow to another environment should replace these references with the corresponding technology, library, macro, and tool files available to them.

## Notes

This repository is meant to demonstrate the organization and implementation of a Hammer-driven ASIC flow, including custom synthesis and physical-design automation. It should be treated as a reference flow rather than an immediately reproducible design environment.
