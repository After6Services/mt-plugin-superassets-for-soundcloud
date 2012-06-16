# SoundCloud Assets

SoundCloud Assets is a Movable Type plugin that allows to import and use SoundCloud tracks as native assets.

# Template Tags

## Overview

SoundCloud tracks work just like other Movable Type's assets and can be accessed via tags *Asset*, *Assets*, *EntryAssets* and *PageAssets*:

    <mt:EntryAssets>
    <mt:if tag="AssetType" eq="soundcloud_track">
        <div>
        <strong><mt:AssetLabel escape="html"></strong>
        <p><mt:AssetDescription escape="html"></p>
        <img src="<mt:AssetThumbnailURL>" width="100" height="100" alt="<mt:AssetLabel escape="html">" />
        </div>
    </mt:if>
    </mt:EntryAssets>

Tracks can be filtered by class name:

    <mt:Assets class="soundcloud_track" lastn="1">
    ...
    </mt:Assets>

## Thumbnails

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
