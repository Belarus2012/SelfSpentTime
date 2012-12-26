# Redmine own time entries

Plugin which allow to setup project permisions to show own time entries to user


## Redmine version

Versions: 1.3.0, 1.3-stable


## Installation

Just put plugin to the folder REDMINE/vendor/plugins and restart Redmine

No migrations, no new gems.


## Usage

Setup role permission "View only own time entries" to allow user see only own time entries


## Changes

Patches:
  Project.allowed_to_condition
  ProjectsController.show
  TimelogController.index
  TimelogController.find_optional_project
  TimeEntryReportsController.report
  TimeEntryReportsController.find_optional_project
