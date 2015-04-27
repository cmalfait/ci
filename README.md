ci
==

Pkg builder for RPM/DEB

The CI repo is used to create versioned RPM/DEB's from open source projects.  The benefit of this is the ability to run the same version of code on multiple OS versions based on a tag in source.

Requirements - git, puppet 3.0 or later
============
The source repo that you clone must have the 00_control directory at the root of the repo.  This will contain the BUILD_VARS file and rpm and debian dirs that will be needed to build our packages.  The directory srurctue will look like this:
 /cloned repo
   /00_control
     BUILD_VARS
     puppet_runner.bash
     /rpm
       pkg_name.spec
     /debian
       rules  

Configuration
=============
BUILD_VARS - this file contains the spec file we want to use, build architecure, pkg name and Version.  Below is a sample for building collectd.

 #Package name
 PKG_NAME=collectd

 #Package version (for the original source)
 PKG_VERSION=5.4.0

 # Current Ubuntu debian control tarball (if the debian folder is absent we'll use this)
 DEBIAN_CTRL_TARBALL=(n/a)

 # Current Ubuntu debian basis:
 DEBIAN_CTRL_URL=(n/a)

 # rpm specific parameters
 RPM_CTRL_SPECFILE=collectd.spec
 RPM_ARCH=x86_64
 RPM_CTRL_TARBALL=
 RPM_CTRL_URL=

SPEC FILE
The spec file for RPMs must reside in the 00_control/rpms directory.  Most open source projects alreay have a .spec file for the project, simply copy it to 00_control/rpm and make any specific changes required.

Puppet_runner.bash
this will call a local puppet run to install any dependencies to build the package. This is not yet in the DCA puppet.  I typically call a build role.   

Here is a sample from the collectd repo
puppet apply --modulepath=../puppet_local/modules -e "include role::collectd_build"

This local apply will install all the packages required to build collectd.

Building
========
On the local dev machine I typically follow these steps:

1. create a build area, mkdir build
2. clone the source repo 
3. clone ci repo
4. clone puppet_local
5. Do our local puppet apply
6. kick off our build

Example - let's build graphite-web
==================================
1. create build area, mkdir build
2. clone the sourcet clone 
 repo 
	git clone https://github.com/cmalfait/graphite-web.git
3. clone ci repo
	git clone https://github.com/cmalfait/ci.git
4. clone puppet_local
	git clone https://github.com/cmalfait/puppet_local.git

5. Do our local puppet apply
        cd graphite-web
        ./00_control/puppet_runner.bash

6. kick off our build
      	cd ../ci
        ./ie_build -tgt rpm -r ../graphite-web

What to expect
==============
If all goes as planned, you'll have a versioned RPM in the 00_packages directory.  This will contain a tarball that was used to create the package.  

A log is also created in the root of the build dir.

Since this uses the native packaging tools, and SRPM is also created in the 00_build dir.
