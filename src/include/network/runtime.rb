# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# **************************************************************************
# File:	include/network/runtime.ycp
# Package:	Network configuration
# Summary:	Runtime routines
# Authors:	Michal Svec <msvec@suse.cz>
#
module Yast
  module NetworkRuntimeInclude
    def initialize_network_runtime(_include_target)
      textdomain "network"
    end

    # Runs external script which updates MTA's configuration.
    #
    # Currently supported MTAs:
    #   - sendmail
    #   - postfix
    def update_mta_config
      Builtins.y2milestone("Updating sendmail and/or postfix configuration.")
      SCR.Execute(
        path(".target.bash"),
        "/usr/lib/sendmail.d/update 2>/dev/null"
      )
      SCR.Execute(path(".target.bash"), "/usr/sbin/config.postfix 2>/dev/null")
    end
  end
end
