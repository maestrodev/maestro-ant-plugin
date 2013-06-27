maestro-ant-plugin
====================

A Maestro Plugin that provides integration with Ant

Task Parameters
---------------

* "Path"

  A valid path to a directory containing the Ant build.xml file.

* "Tasks" (optional)

  Default: ''
  Ant tasks to execute.  Leaving blank will cause default task in build.xml
  to run.

* "Environment" (optional)

  Default: ''
  Environment string to pass to command shell immediately prior to the ant
  executable.

* "PropertyFile" (optional)

  Default: ''
  Location of the ant.properties file for Ant to use.
