<p align="center">
A fidget spinner for your Mac, as seen on [Mastodon](https://mastodon.social/@grishka/113281494735871487) and [Twitter](https://twitter.com/grishka11/status/1844250198136193377).
<img src="/Images/screenshot.jpg"/>
</p>

## How do I run this?

Download from [the releases section](https://github.com/grishka/WidgetSpinner), unzip, [circumvent Gatekeeper](https://disable-gatekeeper.github.io) or use [Sentinel](https://github.com/alienator88/Sentinel).

## How does it work?

It uses a private API, CGSSetWindowTransform, that allows an app to set an arbitrary affine transform on a window. There's also CGSSetWindowWarp that takes a mesh. [Here's some more info about these APIs](https://web.archive.org/web/20190403143211/http://kevin.sb.org/2006/07/23/cgssetwindowwarp-explained/), [another example of using them](https://github.com/sailesha/CGSSetWindowWarp-Sample), and [Sam's thread that inspired me to build this app](https://hachyderm.io/@samhenrigold/113280012443585787).

The dragging of the window is broken when it's rotated.

## Supported system versions

It works flawlessly on modern-ish macOS, but on 10.x, there are graphical glitches around the window as it rotates. I have no idea what causes this and how to fix it and would welcome a fix or an explanation. Might be related to the shadow.

I set the deployment target to 10.9 (Mavericks) but only tested down to 10.12. It may or may not run on even older versions.

## A note on building from source

If you get an error mentioning "libarclite" when building a release version using Xcode 14.3 or newer, you need to either raise the deployment target to 10.12 or newer, or install [the file Apple removed for some reason](https://github.com/kamyarelyasi/Libarclite-Files).