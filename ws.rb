# A program to generate Butterfly Conservation Branch online Newsletters
# Copyright © Graham Phillips 2025
#
# frozen_string_literal: true

require_relative 'lib/utilities'
require_relative 'lib/configurator'
require_relative 'lib/helper'
require_relative 'lib/parser'
require_relative 'lib/article'
require_relative 'lib/issue'
require_relative 'lib/index'
require_relative 'lib/issueslist'
require_relative 'lib/site'
require_relative 'lib/installer'

site = Site.new
if ARGV[0] == '--install'
  installer = Installer.new(site)
  installer.install
else
  site.build
  site.listen
end
