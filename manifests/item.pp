# Add item to OSX dock
define dockutil::item (
  $ensure,
  $item = "/Applications/${name}.app",
  $pos_before = undef,
  $pos_after = undef,
  $pos_value = undef,
  $folder_view = undef,
  $folder_display = undef,
  $folder_sort = undef,
) {
  validate_re($ensure, '^(present|absent)$',
    "${ensure} is not supported for ensure.
    Allowed values are 'present' and 'absent'."
  )

  include ::dockutil
  include ::dockutil::reload

  Class['Dockutil'] ->
    Dockutil::Item[$name] ~>
    Class['Dockutil::Reload']

  if $pos_before != undef {
    Dockutil::Item[$pos_before] -> Dockutil::Item[$name]
  }

  if $pos_after != undef {
    Dockutil::Item[$pos_after] -> Dockutil::Item[$name]
  }

  case $ensure {
    'present': {
      $before = $pos_before ? {
        undef   => '',
        default => "--before '${pos_before}'",
      }

      $after = $pos_after ? {
        undef   => '',
        default => "--after '${pos_after}'",
      }

      if $pos_value != undef {
        validate_re($pos_value, '^(\d+|beginning|end|middle)$',
          "${pos_value} is not supported for pos_value.
          Allowed values are beginning, end, middle, or an integer for a specific position."
        )
        $position = "--position '${pos_value}'"
      } else {
        $position = ''
      }

      if $folder_view != undef {
        validate_re($folder_view, '^(grid|fan|list|automatic)$',
          "${folder_view} is not supported for folder_view.
          Allowed values are grid, fan, list or automatic."
        )
        $view = "--view '${folder_view}'"
      } else {
        $view = ''
      }

      if $folder_display != undef {
        validate_re($folder_display, '^(folder|stack)$',
          "${folder_display} is not supported for folder_display.
          Allowed values are folder or stack."
        )
        $display = "--display '${folder_display}'"
      } else {
        $display = ''
      }

      if $folder_sort != undef {
        validate_re($folder_sort, '^(name|dateadded|datemodified|datecreated|kind)$',
          "${folder_sort} is not supported for folder_sort.
          Allowed values are name, dateadded, datemodified, datecreated or kind."
        )
        $sort = "--sort '${folder_sort}'"
      } else {
        $sort = ''
      }

      exec { "dockutil-add-${name}":
        command => "${boxen::config::cachedir}/dockutil/scripts/dockutil --add '${item}' --label '${name}' ${position} ${after} ${before} ${view} ${display} ${sort} --no-restart",
        onlyif  => "${boxen::config::cachedir}/dockutil/scripts/dockutil --find '${name}' | grep -qx '${name} was not found in /Users/${::luser}/Library/Preferences/com.apple.dock.plist'";
      }
    }

    'absent':{
      exec { "dockutil-remove-${name}":
        command => "${boxen::config::cachedir}/dockutil/scripts/dockutil --remove '${name}' --no-restart",
        onlyif  => "${boxen::config::cachedir}/dockutil/scripts/dockutil --find '${name}' | grep -q '${name} was found'";
      }
    }
  }
}
