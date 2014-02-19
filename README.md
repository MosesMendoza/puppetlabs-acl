ACL (Access Control List)
==============

##Overview

This module adds a type and windows provider for managing permissions.

##Module Description

This module provides a type and provider for managing permissions. Currently, only Windows is supported.


##Setup

###Beginning with ACL

The best way to install this module is with the `puppet module` subcommand.  On your puppet master or local puppet install, execute the following command, optionally specifying your puppet master's `modulepath` in which to install the module:

    $ puppet module install [--modulepath <path>] puppetlabs/acl

See the section [Installing Modules](http://docs.puppetlabs.com/puppet/2.7/reference/modules_installing.html) for more information.

##Usage

MORE TO COME HERE

#### SIDs reference - http://support.microsoft.com/kb/243330

## Testing

    bundle install
    bundle exec rspec spec

## Example Manifests

To run the example manifests you need to either specify this as part of the modules path (--modulepath on the command line, see [ModulePath](http://docs.puppetlabs.com/references/3.stable/configuration.html#modulepath)), or you can create a symlink to the code directory and not have to specify.

### Creating Symlink

First you must take the current code base and create a symlink in the modules directory. Your modules directory may be different, but your code directory will likely be different. Please validate.

With symlinks on Windows, please run the following command an administrative command prompt (substituting the proper directories):

    mklink /D C:\ProgramData\PuppetLabs\puppet\etc\modules\acl C:\code\puppetlabs\puppetlabs-acl

### Running Resource Example

We don't provide a default `puppet resource acl` without a file path. There could be many hundreds or more directories that would need to be searched, interrogated, and dumped out to to the command shell. That could take awhile and negatively affect performance and the information would likely be too much to be useful. However you can get information about a particular directory by using the resource call.

Try the following:

    puppet resource acl c:/windows

Note that inherited ACEs (access control entries) appear in the list as well. Note the results of this against:

    icacls c:\windows

### Running Normal Manifest Example

This works with a simple c:\temp folder. It should give you an idea of what the manifest will do when run.

    puppet apply tests\init.pp

### Running Hiera Manifest Example
From a command line at the top level of the repository:

    puppet apply tests\hiera.pp --hiera_config %cd%\tests\hiera.yaml --path %cd%

We override path (--path) so that we can use it in the hiera config to override the hiera data directory to something local. This isn't perfect but Rob hasn't found a better way to do it yet.

##Limitations

 * The Windows Provider in the first release (at least) will not handle permissions with Symlinks. Please explicitly manage the permissions of the target.

##License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)
