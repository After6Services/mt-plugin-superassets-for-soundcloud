# SoundCloud Assets

SoundCloud Assets is a Movable Type plugin that allows users to import and use SoundCloud tracks as native assets in the Movable Type Asset Manager.  It is part of the SuperAssets series of plugins from After6 Services LLC.

# Installation

After downloading and uncompressing this package:

1. Upload the entire SoundCloudAssets directory within the plugins directory of this distribution to the corresponding plugins directory within the Movable Type installation directory.
    * UNIX example:
        * Copy mt-plugin-soundcloud-assets/plugins/SoundCloudAssets/ into /var/wwww/cgi-bin/mt/plugins/.
    * Windows example:
        * Copy mt-plugin-soundcloud-assets/plugins/SoundCloudAssets/ into C:\webroot\mt-cgi\plugins\.
2. Upload the entire SoundCloudAssets directory within the mt-static directory of this distribution to the corresponding mt-static/plugins directory that your instance of Movable Type is configured to use.  Refer to the StaticWebPath configuration directive within your mt-config.cgi file for the location of the mt-static directory.
    * UNIX example: If the StaticWebPath configuration directive in mt-config.cgi is: **StaticWebPath  /var/www/html/mt-static/**,
        * Copy mt-plugin-soundcloud-assets/mt-static/plugins/SoundCloudAssets/ into /var/www/html/mt-static/plugins/.
    * Windows example: If the StaticWebPath configuration directive in mt-config.cgi is: **StaticWebPath D:/htdocs/mt-static/**,
        * Copy mt-plugin-flickr-assets/mt-static/plugins/SoundCloudAssets/ into D:/htdocs/mt-static/.
        
# Usage

## Template Tags

### Overview

SoundCloud tracks work just like other Movable Type's assets and can be accessed via tags *Asset*, *Assets*, *EntryAssets* and *PageAssets*:

    <mt:EntryAssets>
    <mt:if tag="AssetType" eq="soundcloud track">
        <div>
        <strong><mt:AssetLabel escape="html"></strong>
        <p><mt:AssetDescription escape="html"></p>
        <img src="<mt:AssetThumbnailURL>" width="100" height="100" alt="<mt:AssetLabel escape="html">" />
        </div>
    </mt:if>
    </mt:EntryAssets>

Tracks can be filtered by class name:

    <mt:Assets type="soundcloud_track" lastn="1">
    ...
    </mt:Assets>
    
### Properties

### Thumbnails

When the plugin imports a SoundCloud track, it saves the track's default 100x100px artwork image as the asset's thumbnail. A default image is used when the artwork is not available.

The plugin provides access to SoundCloud track thumbnails through the standard tag *AssetThumbnailURL* and allows downscaling the image via *width* or *height* attributes:

        <img src="<mt:AssetThumbnailURL width="80">" width="80" alt="<mt:AssetLabel escape="html">" />

## Track Properties

There are a few extra asset properties accessible in templates:

* *soundcloud_track_id* - external track id
* *soundcloud_track_permalink* - track URL path element, e.g. "my-song" (not the full URL)
* *soundcloud_track_user_id* - track owner's id
* *soundcloud_track_user_permalink* - track owner's URL path element
* *soundcloud_track_user_name* - track owner's nickname

        Track by <a href="http://soundcloud.com/<mt:AssetProperty property="soundcloud_track_user_permalink">"><mt:AssetProperty property="soundcloud_track_user_name"></a>

# Customizing default player

By default, the plugin renders the default iframe-based HTML5 version of the player for tracks embedded via the rich text editor. To customize the player, add a blog or system-level template module called "SoundCloud Player" with your code. The asset object and its blog will be available in the template context.

# Support

This plugin has not been tested with any version of Movable Type prior to Movable Type 4.38.

Although After6 Services LLC has developed this plugin, After6 only provides support for this plugin as part of a Movable Type support agreement that references this plugin by name.

# License

This plugin is licensed under The BSD 2-Clause License, http://www.opensource.org/licenses/bsd-license.php.  See LICENSE.md for the exact license.

# Authorship

SoundCloud Assets was originally written by Arseni Mouchinski with help from Dave Aiello and Jeremy King.

# Copyright

Copyright &copy; 2012, After6 Services LLC.  All Rights Reserved.

SoundCloud is a trademark of SoundCloud Ltd.

SuperAssets is a trademark of After6 Services LLC.

Movable Type is a registered trademark of Six Apart Limited.

Trademarks, product names, company names, or logos used in connection with this repository are the property of their respective owners and references do not imply any endorsement, sponsorship, or affiliation with After6 Services LLC unless otherwise specified.

