<%args>
$doc
$title => undef
$type  => 'story'
$style => 'blackMedUnderlinedLink'
$oc_js => undef
</%args>
<%init>;
my $uid = $doc->get_user__id;
my $co = defined $uid && $uid == get_user_id;
$title = $doc->get_title unless defined $title;
return $title unless $co || $doc->get_version;
return $title if $type eq 'media' and not $doc->get_file_name;
my $id = $doc->get_id;
my $uri = escape_html($doc->get_primary_uri);

# Return a simple link unless we've been givin a JS reference to a an
# output channel ID.
return qq{<a href="$uri" } .
  qq{onclick="var newWin = window.open('/workflow/profile/preview/$type/$id?checkout=$co', 'preview_'); newWin.focus(true); return false;" } .
  qq{class="$style" target="preview_} .
  SERVER_WINDOW_NAME . qq{" title="$uri" alt="Preview">$title</a>}
  unless $oc_js;

# If we got here, We need to actually load the link based on an oc ID.
return qq{<a href="$uri" onClick="window.open('/workflow/profile/preview/$type/$id/' + $oc_js, 'preview_<% SERVER_WINDOW_NAME %>'); return false;" title="$uri"><img src="/media/images/$lang_key/preview_lgreen.gif" alt="Preview" title="Preview $uri" border="0" width="74" height="20"></a>};
</%init>
